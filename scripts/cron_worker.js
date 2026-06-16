/**
 * cron_worker.js — Tamamen ÜCRETSİZ backend.
 *
 * GitHub Actions / cron-job.org tarafından zamanlı çalıştırılır.
 * Firebase Admin SDK ile (service account, GitHub Secret'ta) çalışır.
 * Cloud Functions / Blaze planı GEREKTİRMEZ. FCM gönderimi ücretsizdir.
 *
 * İki iş yapar:
 *  1) Davet kuyruğu: 'notifications' koleksiyonundaki gönderilmemiş davetleri
 *     hedef kullanıcıların FCM token'larına yollar, sonra siler.
 *  2) Süresi geçen etkinlikler: endAt < now olanları bulur; gelmeyenlere
 *     (rsvp = no/pending) no-show metin bildirimi atar, "missed" kaydı yazar;
 *     sonra etkinliği ve rsvps alt-koleksiyonunu siler.
 *
 * İdempotency: no-show bildirimi 'noShowProcessed' bayrağı ile en fazla bir kez
 * gönderilir; çökme/timeout durumunda çift bildirim oluşmaz.
 */

const admin = require("firebase-admin");

// Service account JSON, ortam değişkeninden (GitHub Secret) okunur.
// Olası BOM (U+FEFF) ve baştaki/sondaki boşluklar temizlenir.
const rawServiceAccount = (process.env.FIREBASE_SERVICE_ACCOUNT || "")
  .replace(/^﻿/, "")
  .trim();

if (!rawServiceAccount) {
  console.error("FIREBASE_SERVICE_ACCOUNT ortam değişkeni boş/eksik.");
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(rawServiceAccount);
} catch (e) {
  console.error("FIREBASE_SERVICE_ACCOUNT geçerli bir JSON değil.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

// Toplam başarısız iş sayısı (CI exit kodu için).
let failures = 0;

// FCM token'ları artık herkese açık profilde DEĞİL, users/{uid}/private/push
// altında tutulur (gizlilik). Admin SDK kuralları bypass eder, okuyabilir.
function pushDocRef(uid) {
  return db.collection("users").doc(uid).collection("private").doc("push");
}

// Ölü/geçersiz sayılan ve temizlenmesi gereken FCM hata kodları.
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

/**
 * Verilen uid'ler için token haritası döndürür: Map<uid, string[]>.
 * N+1 yerine tek `getAll` round-trip kullanır (ücretsiz okuma kotası koruması).
 */
async function getTokenMapForUids(uids) {
  const unique = [...new Set(uids)];
  const map = new Map();
  if (unique.length === 0) return map;
  const refs = unique.map((uid) => pushDocRef(uid));
  const snaps = await db.getAll(...refs);
  snaps.forEach((snap, i) => {
    const tokens = (snap.exists && snap.data().fcmTokens) || [];
    if (tokens.length) map.set(unique[i], tokens);
  });
  return map;
}

/**
 * Token haritasına bildirim gönderir; ölü token'ları sahibinin private/push
 * dokümanından temizler. Her 500'lük FCM chunk'ı izole try/catch içinde.
 * Döner: { attempted, allSucceeded }
 */
async function sendToTokenMap(tokenMap, title, body, data = {}) {
  const tokenToUid = new Map();
  const allTokens = [];
  for (const [uid, tokens] of tokenMap) {
    for (const t of tokens) {
      if (!tokenToUid.has(t)) {
        tokenToUid.set(t, uid);
        allTokens.push(t);
      }
    }
  }
  if (allTokens.length === 0) return { attempted: 0, allSucceeded: true };

  const deadByUid = new Map(); // uid -> Set(token)
  let allSucceeded = true;

  for (let i = 0; i < allTokens.length; i += 500) {
    const chunk = allTokens.slice(i, i + 500);
    try {
      const res = await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data,
      });
      res.responses.forEach((r, j) => {
        if (!r.success && r.error && DEAD_TOKEN_CODES.has(r.error.code)) {
          const tok = chunk[j];
          const uid = tokenToUid.get(tok);
          if (!deadByUid.has(uid)) deadByUid.set(uid, new Set());
          deadByUid.get(uid).add(tok);
        }
      });
    } catch (e) {
      allSucceeded = false;
      console.error("FCM chunk gönderimi başarısız:", e.message);
    }
  }

  // Ölü token'ları temizle (arrayRemove).
  for (const [uid, toks] of deadByUid) {
    try {
      await pushDocRef(uid).set(
        { fcmTokens: admin.firestore.FieldValue.arrayRemove(...[...toks]) },
        { merge: true }
      );
      console.log(`Pruned ${toks.size} dead token(s) for ${uid}`);
    } catch (e) {
      console.error(`Token temizliği başarısız (${uid}):`, e.message);
    }
  }

  return { attempted: allTokens.length, allSucceeded };
}

/** Bir işlem listesini ≤500'lük batch'ler hâlinde commit eder. */
async function commitInChunks(ops) {
  const LIMIT = 450; // 500 sınırının altında güvenli pay
  for (let i = 0; i < ops.length; i += LIMIT) {
    const batch = db.batch();
    for (const op of ops.slice(i, i + LIMIT)) op(batch);
    await batch.commit();
  }
}

/** 1) Davet kuyruğunu işle */
async function processInvites() {
  const snap = await db
    .collection("notifications")
    .where("sent", "==", false)
    .limit(50)
    .get();

  for (const doc of snap.docs) {
    const n = doc.data();
    try {
      const tokenMap = await getTokenMapForUids(n.targetUids || []);
      const { allSucceeded } = await sendToTokenMap(tokenMap, n.title, n.body, {
        kind: n.kind || "invite",
        eventId: n.eventId || "",
      });
      // Yalnızca gönderim tam başarılıysa kuyruğu temizle; aksi halde bir
      // sonraki turda tekrar denenir (chunk bazlı en-az-bir-kez teslim).
      if (allSucceeded) {
        await doc.ref.delete();
        console.log(`Invite sent for event ${n.eventId}`);
      } else {
        console.warn(`Invite kısmen başarısız (${n.eventId}), tekrar denenecek`);
      }
    } catch (e) {
      failures++;
      console.error("Invite send failed:", e.message);
    }
  }
}

/** 2) Süresi geçen etkinlikleri işle: no-show bildirimi + missed kaydı + silme */
async function processExpiredEvents() {
  const now = admin.firestore.Timestamp.now();
  const snap = await db
    .collection("events")
    .where("endAt", "<", now)
    .limit(50)
    .get();

  for (const doc of snap.docs) {
    const e = doc.data();
    const eventId = doc.id;
    try {
      const rsvpsSnap = await doc.ref.collection("rsvps").get();

      // İdempotency: no-show işlemi yalnızca bir kez. Bayrak commit'lendikten
      // sonra (event silinene kadar tekrar görünse bile) yeniden gönderilmez.
      if (!e.noShowProcessed) {
        const noShowUids = [];
        for (const r of rsvpsSnap.docs) {
          const st = r.data().status;
          if (st === "no" || st === "pending") noShowUids.push(r.id);
        }

        if (noShowUids.length > 0) {
          // No-show görseli + mesajı, davetli "Kaçırdıklarım" ekranında görsün.
          const missed = {
            eventId,
            title: e.title || "",
            type: e.type || "other",
            hostUsername: e.hostUsername || "",
            imageBase64: e.imageBase64 || "",
            noShowMessage: e.noShowMessage || "",
            endAt: e.endAt || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          };

          // 1) missed kayıtları + bayrağı KALICI yaz (çift göndermeyi önler).
          const ops = noShowUids.map((uid) => (batch) =>
            batch.set(
              db.collection("users").doc(uid).collection("missed").doc(eventId),
              missed
            )
          );
          ops.push((batch) => batch.update(doc.ref, { noShowProcessed: true }));
          await commitInChunks(ops);

          // 2) SADECE METİN push gönder + ölü token temizle (en fazla bir kez).
          const tokenMap = await getTokenMapForUids(noShowUids);
          const body = e.noShowMessage || `"${e.title}" etkinliğini kaçırdın.`;
          await sendToTokenMap(tokenMap, "Bir etkinliği kaçırdın", body, {
            kind: "no_show",
            eventTitle: e.title || "",
          });
          console.log(`No-show processed for ${eventId} -> ${noShowUids.length} users`);
        } else {
          // Gelmeyen yok: tutarlılık için bayrağı yine de koy.
          await doc.ref.update({ noShowProcessed: true });
        }
      }

      // Etkinliği ve rsvps alt-koleksiyonunu sil (≤500'lük batch'ler).
      const delOps = rsvpsSnap.docs.map((r) => (batch) => batch.delete(r.ref));
      delOps.push((batch) => batch.delete(doc.ref));
      await commitInChunks(delOps);
      console.log(`Deleted expired event ${eventId}`);
    } catch (err) {
      failures++;
      console.error(`Failed processing event ${eventId}:`, err.message);
    }
  }
}

(async () => {
  console.log("Cron worker started:", new Date().toISOString());
  await processInvites();
  await processExpiredEvents();
  console.log(`Cron worker finished. failures=${failures}`);
  process.exit(failures > 0 ? 1 : 0);
})().catch((e) => {
  console.error("Fatal cron error:", e && e.message ? e.message : e);
  process.exit(1);
});
