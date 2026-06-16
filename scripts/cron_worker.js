/**
 * cron_worker.js — Tamamen ÜCRETSİZ backend.
 *
 * GitHub Actions tarafından zamanlı çalıştırılır (.github/workflows/cron.yml).
 * Firebase Admin SDK ile (service account, GitHub Secret'ta) çalışır.
 * Cloud Functions / Blaze planı GEREKTİRMEZ. FCM gönderimi ücretsizdir.
 *
 * İki iş yapar:
 *  1) Davet kuyruğu: 'notifications' koleksiyonundaki gönderilmemiş davetleri
 *     hedef kullanıcıların FCM token'larına yollar, sonra siler.
 *  2) Süresi geçen etkinlikler: endAt < now olanları bulur; gelmeyenlere
 *     (rsvp = no/pending) no-show görsel+metin bildirimi atar; sonra etkinliği
 *     ve rsvps alt-koleksiyonunu siler.
 */

const admin = require("firebase-admin");

// Service account JSON, ortam değişkeninden (GitHub Secret) okunur.
// Olası BOM (U+FEFF) ve baştaki/sondaki boşluklar temizlenir (JSON.parse hatasını önler).
const rawServiceAccount = (process.env.FIREBASE_SERVICE_ACCOUNT || "")
  .replace(/^﻿/, "")
  .trim();
const serviceAccount = JSON.parse(rawServiceAccount);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

// FCM data payload'ında base64 görsel taşımak limitlidir (4KB). Bu yüzden
// no-show görselini bildirim olarak değil, data ile "var" bilgisi olarak
// göndeririz; istemci açınca Firestore'dan çekemez (event silinmiş olur),
// bu yüzden metni bildirimde, görseli mümkünse imageUrl yerine kısa data
// ile iletiriz. Pratikte: no-show görseli base64 büyükse sadece metin gider.
const MAX_DATA_IMAGE = 3000; // ~3KB

async function getTokensForUids(uids) {
  const tokens = [];
  for (const uid of uids) {
    const snap = await db.collection("users").doc(uid).get();
    if (snap.exists) {
      const t = snap.data().fcmTokens || [];
      tokens.push(...t);
    }
  }
  return [...new Set(tokens)];
}

async function sendToTokens(tokens, title, body, data = {}) {
  if (tokens.length === 0) return;
  // FCM çoklu gönderim (her seferinde max 500 token)
  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }
  for (const chunk of chunks) {
    await messaging.sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      data,
    });
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
      const tokens = await getTokensForUids(n.targetUids || []);
      await sendToTokens(tokens, n.title, n.body, {
        kind: n.kind || "invite",
        eventId: n.eventId || "",
      });
      await doc.ref.delete(); // gönderildi → kuyruğu temizle
      console.log(`Invite sent for event ${n.eventId} -> ${tokens.length} tokens`);
    } catch (e) {
      console.error("Invite send failed:", e.message);
    }
  }
}

/** 2) Süresi geçen etkinlikleri işle: no-show bildirimi + silme */
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
      // RSVP'leri oku, gelmeyenleri (no/pending) bul
      const rsvpsSnap = await doc.ref.collection("rsvps").get();
      const noShowUids = [];
      for (const r of rsvpsSnap.docs) {
        const st = r.data().status;
        if (st === "no" || st === "pending") noShowUids.push(r.id);
      }

      // No-show bildirimi (görsel + metin)
      if (noShowUids.length > 0) {
        const tokens = await getTokensForUids(noShowUids);
        const body = e.noShowMessage || `"${e.title}" etkinliğini kaçırdın.`;
        const data = { kind: "no_show", eventTitle: e.title || "" };
        // Küçükse görseli data ile ilet
        if (e.noShowImageBase64 && e.noShowImageBase64.length < MAX_DATA_IMAGE) {
          data.imageBase64 = e.noShowImageBase64;
        }
        await sendToTokens(tokens, "Etkinliği kaçırdın", body, data);
        console.log(`No-show sent for ${eventId} -> ${tokens.length} tokens`);
      }

      // Sil: önce rsvps alt-koleksiyonu, sonra event
      const batch = db.batch();
      rsvpsSnap.docs.forEach((r) => batch.delete(r.ref));
      batch.delete(doc.ref);
      await batch.commit();
      console.log(`Deleted expired event ${eventId}`);
    } catch (err) {
      console.error(`Failed processing event ${eventId}:`, err.message);
    }
  }
}

(async () => {
  console.log("Cron worker started:", new Date().toISOString());
  await processInvites();
  await processExpiredEvents();
  console.log("Cron worker finished.");
  process.exit(0);
})();
