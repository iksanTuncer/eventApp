# Firestore Şema (Veri Modeli)

Tamamen ücretsiz Spark planına uygun. Fotoğraflar base64 olarak döküman içinde.

## Koleksiyon: `users/{uid}`
Kullanıcı profili. uid = Firebase Auth uid.

| Alan          | Tip       | Açıklama |
|---------------|-----------|----------|
| uid           | string    | Auth uid (kopya) |
| email         | string    | Kayıt e-postası |
| username      | string    | Onboarding'de zorunlu, unique olması önerilir |
| photoBase64   | string?   | Opsiyonel profil fotoğrafı (sıkıştırılmış JPEG, ~<200KB) |
| interests     | array<str>| İlgilenilen event tipleri: ["filter_coffee","tea",...] |
| createdAt     | timestamp | |

> ⚠️ `fcmTokens` ARTIK bu dökümanda DEĞİL. Profil herkese-okunur olduğu için
> token'lar gizlilik amacıyla `users/{uid}/private/push` altına taşındı.

### Alt-koleksiyon: `users/{uid}/private/{doc}`
Sadece sahibi (ve Admin SDK ile cron) okur/yazar. Güvenlik kuralı: `isSelf(uid)`.

| Doküman | Alan       | Tip        | Açıklama |
|---------|------------|------------|----------|
| `push`  | fcmTokens  | array<str> | Cihaz FCM token'ları (çoklu cihaz). Ölü token'lar cron'da temizlenir. |

### Alt-koleksiyon: `users/{uid}/missed/{eventId}`
Kaçırılan (no/pending) ve süresi geçip silinen etkinliklerin görsel+mesaj kaydı.
Yalnızca cron worker (Admin SDK) yazar; sahibi okur/siler.

| Alan         | Tip        | Açıklama |
|--------------|------------|----------|
| eventId      | string     | |
| title        | string     | |
| type         | string     | |
| hostUsername | string     | |
| imageBase64  | string     | Etkinlik görseli |
| noShowMessage| string     | Gelmeyene gösterilen mesaj |
| endAt        | timestamp? | |
| createdAt    | timestamp  | serverTimestamp |

## Koleksiyon: `events/{eventId}`
Bir etkinlik. eventId = otomatik id.

| Alan            | Tip        | Açıklama |
|-----------------|------------|----------|
| eventId         | string     | (kopya) |
| hostUid         | string     | Oluşturan kullanıcı |
| hostUsername    | string     | Liste gösteriminde hızlı erişim |
| type            | string     | "filter_coffee" \| "tea" \| "cold_drink" \| "turkish_coffee" \| "other" |
| title           | string     | Hazır tipte ön-dolu, "other"da serbest |
| imageBase64     | string     | Etkinlik görseli (hazır veya kullanıcı değişimi) |
| description     | string?    | Opsiyonel açıklama |
| startAt         | timestamp  | Başlangıç tarih+saat |
| endAt           | timestamp  | Bitiş tarih+saat (silme & no-show tetikleyici) |
| locationMode    | string     | "map" \| "text" |
| locationText    | string?    | Serbest metin lokasyon |
| lat             | number?    | map modunda enlem |
| lng             | number?    | map modunda boylam |
| inviteeUids     | array<str> | Davet edilen kullanıcı uid listesi |
| noShowImageBase64 | string?  | Gelmeyenlere gidecek görsel |
| noShowMessage   | string?    | Gelmeyenlere gidecek metin |
| status          | string     | "active" \| "ended" |
| noShowProcessed | bool?      | Cron no-show bildirimini + missed kayıtlarını yazdı mı (idempotency bayrağı) |
| createdAt       | timestamp  | |

### Alt-koleksiyon: `events/{eventId}/rsvps/{uid}`
Davetlinin katılım yanıtı.

| Alan      | Tip       | Açıklama |
|-----------|-----------|----------|
| uid       | string    | Davetli uid |
| username  | string    | Hızlı gösterim |
| status    | string    | "pending" \| "yes" \| "no" |
| respondedAt | timestamp? | |

## Koleksiyon: `notifications/{id}`
İstemci davet görevi yazar; cron worker (Admin SDK) okur, FCM gönderir, siler.

| Alan       | Tip        | Açıklama |
|------------|------------|----------|
| kind       | string     | "invite" (istemci yalnızca bunu yazabilir) |
| eventId    | string     | İlgili etkinlik |
| targetUids | array<str> | Hedef davetliler (etkinliğin GERÇEK davetlilerinin alt kümesi olmalı) |
| title      | string     | |
| body       | string     | |
| sent       | bool       | İstemci `false` yazar |
| createdAt  | timestamp  | |

> Güvenlik: kural, yazanın etkinliğin host'u olmasını ve `targetUids`'in
> `inviteeUids` içinde olmasını zorunlu kılar (rastgele push spam'i engellenir).

## Silme / No-show Kuralı
`endAt` geçtiğinde **yalnızca cron worker** (scripts/cron_worker.js) yürütür:
1. `noShowProcessed` değilse: RSVP'si "no"/"pending" olanlar için `missed` kaydı
   yaz + bayrağı KALICI işaretle → sonra no-show metin push'u gönder (en fazla
   bir kez; çift bildirimi önler).
2. `rsvps` alt-koleksiyonunu ve `events/{eventId}` dökümanını ≤500'lük batch'lerle sil.

> İstemci-taraflı temizlik kaldırıldı (cron ile yarış + kaybolan missed kaydı riski).

## Query İndeksleri (firestore.indexes.json)
- events: inviteeUids (array-contains) + endAt (asc) — davet edildiğim aktif eventler
- events: hostUid (==) + endAt (asc) — düzenlediğim eventler
- events: processed (==) + endAt (asc) — (eski) cron indeksi; cron artık yalnızca
  `endAt < now` ile sorgular, ek indeks gerektirmez.
