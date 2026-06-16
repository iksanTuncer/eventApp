# CLAUDE.md — Proje Yönergesi (Event Daveti Uygulaması)

> Bu dosya Claude Code içindir. Projeyi inşa ederken bu kurallara uy.
> Dil: Arayüz Türkçe, kod/değişken/yorum İngilizce.

## 1. Proje Özeti

Hobi amaçlı, Android + iOS mobil uygulama. Kullanıcılar etkinlik (event)
düzenler ve listeden seçtikleri kişilere davetiye gönderir. Davetliler
katılım durumunu bildirir. Etkinlik bitiş zamanında gelmeyen katılımcılara
özel bir görsel + metin bildirim gider. Bitiş zamanı geçen etkinlikler ve
ilgili tüm verileri veritabanından otomatik silinir.

**Framework:** Flutter (Dart) — tek kod tabanı, Android + iOS.
**Backend:** Firebase (Spark / ÜCRETSİZ plan, KREDİ KARTI YOK).
  - Auth: Firebase Authentication (email + password)
  - Veritabanı: Cloud Firestore
  - Bildirim: Firebase Cloud Messaging (FCM)
  - Fotoğraf: Firestore içinde küçük boyutlu base64 (Firebase Storage KULLANMA — 2026'da kart istiyor)
**Zamanlama:** GitHub Actions cron (ücretsiz) + istemci-taraflı kontrol birlikte.

## 2. ÜCRETSİZ KALMA KURALLARI (ÇOK ÖNEMLİ — İHLAL ETME)

Firebase 2026 itibarıyla Storage ve Cloud Functions için Blaze (kartlı) plan
ister. Bu proje kart bağlamadan çalışmak ZORUNDA. Bu yüzden:

- ❌ Firebase Cloud Storage KULLANMA. → ✅ Fotoğrafları sıkıştırıp (maks ~200KB,
  uzun kenar 800px, JPEG q70) base64 string olarak Firestore'a yaz.
- ❌ Firebase Cloud Functions (zamanlanmış) KULLANMA. → ✅ Süre kontrolü iki yoldan:
  1. **İstemci-taraflı:** Uygulama açıldığında `CleanupService` süresi geçen
     eventleri kontrol eder, "no-show" bildirimini yerelde gönderir, sonra siler.
  2. **GitHub Actions cron:** `scripts/cron_worker.js` her 5 dakikada bir
     çalışır, süresi geçen eventleri bulur, FCM ile bildirim atar, Firestore'dan
     siler. Firebase Admin SDK + service account JSON ile (GitHub Secrets'ta saklı).
- Firestore limitlerini koru: günlük 50K okuma / 20K yazma. Query'leri dar tut,
  gereksiz dinleyici (listener) açma, `limit()` kullan.
- FCM tamamen ücretsiz, sınırsız → bildirimler güvenle FCM ile.

## 3. Uygulama Akışı (Ekranlar)

1. **Auth (Kayıt/Giriş):** email + password. (lib/screens/auth/)
2. **Onboarding 1 — Profil:** username (zorunlu) + fotoğraf (opsiyonel, base64).
3. **Onboarding 2 — İlgi Seçimi:** ilgilenilen event tipleri seçilir.
4. **Ana Ekran:** Davet edildiğim eventler + Düzenlediğim eventler sekmeleri.
5. **Event Oluştur:** Önce tip seç (hazır 4 tip + "Diğer").
   - Hazır tipler: Filtre Kahve, Çay, Soğuk İçecek, Türk Kahvesi.
   - Her hazır tip kendi "set" ekranına yönlendirir (önceden tanımlı görsel +
     başlık, kullanıcı görseli değiştirebilir).
   - "Diğer": kullanıcı her alanı serbest doldurur (unique form).
6. **Event Set Formu (ortak):**
   - Görsel (hazır geliyor / değiştirilebilir, base64)
   - Başlangıç tarih+saat (picker), Bitiş tarih+saat (picker)
   - Lokasyon: cihaz GPS ile harita konumu İŞARETLE **veya** serbest metin
   - Davetli listesi: kullanıcı listesinden seç (multi-select)
   - "No-show mesajı": gelmeyenlere gidecek görsel + metin (oluştururken belirlenir)
7. **Davetiye:** Davet anında davetlilere FCM bildirimi gider.
8. **Davet Yanıtı:** Davetli "Katılacağım / Katılmayacağım" der.
9. **Event Detay (düzenleyene özel):** Katılacaklar / Katılmayacaklar / Yanıtsızlar listesi.
10. **Bitiş anında:** Gelmeyen (RSVP=no veya yanıtsız) kullanıcılara no-show
    görsel+metin bildirimi → sonra event + tüm alt verileri silinir.

## 4. Veri Modeli (Firestore)

Detay: `firestore/SCHEMA.md`. Özet koleksiyonlar:
- `users/{uid}`: profil, username, photoBase64, interests[], fcmTokens[]
- `events/{eventId}`: tüm event verisi (host, type, görsel, zamanlar, lokasyon,
  noShowMessage, invitees[], status)
- `events/{eventId}/rsvps/{uid}`: katılım yanıtları (status: pending/yes/no)

Silme: event silinince alt-koleksiyon `rsvps` de silinmeli (batch/recursive).

## 5. Kod Standartları

- State yönetimi: `provider` paketi (basit, ücretsiz, hobi için yeterli).
- Klasörler: models / services / screens / widgets / theme / utils.
- Her Firestore erişimi `services/` altında soyutlanır (ekranlar doğrudan
  Firestore çağırmaz).
- Tema: lib/theme/app_theme.dart — sıcak içecek temalı palet.
- Türkçe arayüz metinleri lib/utils/strings.dart içinde.
- Hata yönetimi: her async çağrı try/catch, kullanıcıya SnackBar ile bilgi.

## 6. Kurulum Sırası (Claude Code yapacaklar)

1. `flutter create` ile iskeleti kur, `pubspec.yaml`'daki bağımlılıkları ekle.
2. FlutterFire CLI ile Firebase'i bağla (`flutterfire configure`) → firebase_options.dart üretir.
3. Firebase Console'da: Email/Password auth aç, Firestore oluştur (test→sonra kurallar).
4. `firestore/firestore.rules` ve `firestore/firestore.indexes.json` deploy et.
5. FCM için Android `google-services.json`, iOS `GoogleService-Info.plist` ekle,
   iOS push sertifikası (APNs key) Firebase'e yükle.
6. GitHub repo'ya service account JSON'u Secret olarak ekle, cron workflow aktif.
7. `flutter run` ile test.

## 7. Yapma / Dikkat
- Asla gerçek API key / service account'u repoya commit etme. `.gitignore`'a bak.
- iOS push için fiziksel cihaz + Apple Developer hesabı gerekir (simülatörde push çalışmaz).
- Konum izni: Android & iOS Info.plist / AndroidManifest izinleri eklenmeli (aşağıda hazır).
- Base64 fotoğrafı 1MB altında tut; Firestore döküman limiti 1MB.
