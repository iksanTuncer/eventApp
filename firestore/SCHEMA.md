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
| fcmTokens     | array<str>| Bildirim için cihaz token'ları (çoklu cihaz) |
| createdAt     | timestamp | |

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
| status          | string     | "active" \| "ended" (işlendi, silinmeyi bekliyor) |
| processed       | bool       | Cron/istemci no-show bildirimini gönderdi mi |
| createdAt       | timestamp  | |

### Alt-koleksiyon: `events/{eventId}/rsvps/{uid}`
Davetlinin katılım yanıtı.

| Alan      | Tip       | Açıklama |
|-----------|-----------|----------|
| uid       | string    | Davetli uid |
| username  | string    | Hızlı gösterim |
| status    | string    | "pending" \| "yes" \| "no" |
| respondedAt | timestamp? | |

## Silme Kuralı
`endAt` geçtiğinde:
1. RSVP'si "no" veya "pending" olan davetlilere no-show bildirimi (görsel+metin) gönder.
2. `rsvps` alt-koleksiyonunu sil.
3. `events/{eventId}` dökümanını sil.

Bu iş hem GitHub Actions cron (scripts/cron_worker.js) hem de istemci açılışında
(lib/services/cleanup_service.dart) yapılır. `processed` bayrağı çift bildirimi önler.

## Query İndeksleri (firestore.indexes.json)
- events: inviteeUids (array-contains) + endAt (asc) — davet edildiğim aktif eventler
- events: hostUid (==) + endAt (asc) — düzenlediğim eventler
- events: endAt (asc) + processed (==) — cron'un süresi geçenleri bulması
