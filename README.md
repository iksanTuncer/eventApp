# Buluşma — Etkinlik Daveti Uygulaması (Tamamen Ücretsiz)

Sıcak içecek temalı, davet bazlı etkinlik uygulaması. **Flutter** (Android + iOS),
**Firebase** (ücretsiz Spark planı), **GitHub Actions** (ücretsiz cron) ile çalışır.
**Kredi kartı bağlamadan** çalışacak şekilde tasarlandı.

## Neden bu mimari? (Önemli)

Firebase 2026'da bazı servisleri ücretsiz plandan çıkardı:
- **Firebase Cloud Storage** artık kredi kartı (Blaze) ister → bu yüzden fotoğrafları
  **sıkıştırıp Firestore'a base64** olarak yazıyoruz. Storage kullanmıyoruz.
- **Zamanlanmış Cloud Functions** kart ister → bu yüzden bildirim gönderme ve süresi
  geçen etkinlikleri silme işini **GitHub Actions cron** (tamamen ücretsiz) yapıyor.
- **Authentication, Firestore, Cloud Messaging (FCM)** ücretsiz planda çalışır.

Sonuç: Kart bağlamadan tam çalışan uygulama. Tek istisna — Google Maps SDK'si
ücretsiz kotada çalışır ama Google Cloud'da kart isteyebilir; istemezsen
**konumu metin olarak** girebilirsin (uygulama iki modu da destekler).

## Klasör Yapısı

```
event_app/
├── CLAUDE.md                 # Claude Code yönergesi (önce bunu oku)
├── README.md                 # Bu dosya
├── pubspec.yaml              # Flutter bağımlılıkları
├── firebase.json             # Firebase CLI yapılandırması
├── android_setup.md          # Android adımları
├── ios_setup.md              # iOS adımları
├── firestore/
│   ├── SCHEMA.md             # Veri modeli
│   ├── firestore.rules       # Güvenlik kuralları
│   └── firestore.indexes.json
├── lib/
│   ├── main.dart
│   ├── models/               # AppUser, AppEvent, Rsvp
│   ├── services/             # auth, user, event, image, notification, cleanup, location
│   ├── screens/              # auth, onboarding, events, home
│   ├── widgets/              # event_card
│   ├── theme/                # app_theme
│   └── utils/                # constants, strings
├── scripts/
│   ├── cron_worker.js        # Ücretsiz backend (FCM + silme)
│   └── package.json
├── .github/workflows/
│   └── cron.yml              # GitHub Actions cron (her 5 dk)
└── assets/event_images/      # Hazır etkinlik görselleri (sen ekle)
```

## Kurulum (Adım Adım)

### 0. Gereksinimler
- Flutter SDK (3.3+), Dart
- Bir Google hesabı (Firebase için)
- Bir GitHub hesabı (cron için)
- iOS için: Mac + Xcode + Apple Developer hesabı (push bildirim için zorunlu)

### 1. Flutter iskeletini kur
```bash
cd event_app
flutter create . --org com.seninadin.bulusma --platforms=android,ios
flutter pub get
```
> Bu komut mevcut `lib/`, `pubspec.yaml` dosyalarını koruyup eksik platform
> klasörlerini (android/, ios/) oluşturur.

### 2. Firebase projesi oluştur
1. https://console.firebase.google.com → "Proje ekle" (ücretsiz, kart yok).
2. **Authentication** > Sign-in method > **Email/Password**'ü etkinleştir.
3. **Firestore Database** > veritabanı oluştur (production modda başla).
4. **Cloud Messaging** otomatik aktif.

### 3. FlutterFire ile bağla
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Bu, `lib/firebase_options.dart` üretir ve platform dosyalarını ayarlar.
Android `google-services.json` ve iOS `GoogleService-Info.plist` indirilip
yerlerine konmalı (bkz. android_setup.md / ios_setup.md).

### 4. Firestore kuralları ve indeksleri deploy et
```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

### 5. Hazır görselleri ekle
`assets/event_images/` içine şu dosyaları koy (kendi görsellerin, telifsiz):
`filter_coffee.jpg`, `tea.jpg`, `cold_drink.jpg`, `turkish_coffee.jpg`, `other.jpg`

### 6. Platform ayarları
- Android: `android_setup.md` adımlarını uygula (izinler, maps key, gradle).
- iOS: `ios_setup.md` adımlarını uygula (Info.plist, push capability, APNs key).

### 7. Ücretsiz backend'i (cron) kur
1. Bu projeyi bir GitHub reposuna push et (`.gitignore` hassas dosyaları korur).
2. Firebase Console > Proje Ayarları > **Hizmet hesapları** > "Yeni özel anahtar
   oluştur" → bir JSON dosyası iner.
3. GitHub repo > Settings > Secrets and variables > Actions > **New repository secret**:
   - Ad: `FIREBASE_SERVICE_ACCOUNT`
   - Değer: indirdiğin JSON dosyasının TÜM içeriği (tek seferde yapıştır).
4. `.github/workflows/cron.yml` zaten hazır; push edince her 5 dakikada çalışır.
   Actions sekmesinden "Run workflow" ile elle de test edebilirsin.

### 8. Çalıştır
```bash
flutter run            # bağlı cihaz/emülatörde
```
> iOS push testi için fiziksel cihaz şart (simülatörde FCM push çalışmaz).

## Akış Özeti
1. Kayıt (email+şifre) → 2. Profil (username + opsiyonel foto) → 3. İlgi seçimi
→ Ana ekran (Davetlerim / Etkinliklerim) → "Etkinlik Oluştur" → tip seç → formu
doldur (görsel, tarih/saat, konum, davetliler, no-show mesajı) → davetler kuyruğa
yazılır → cron worker FCM bildirimini yollar → davetli "Katılacağım/Katılmayacağım"
der → host detayda listeleri görür → bitiş saatinde gelmeyenlere no-show bildirimi
gider → etkinlik ve tüm verileri silinir (cron + istemci, iki yönlü güvence).

## Ücretsiz Kalma — Limitler
- Firestore: 50K okuma / 20K yazma / gün, 1GB depolama. Hobi için fazlasıyla yeter.
- FCM: sınırsız ücretsiz.
- GitHub Actions: aylık 2000 dakika ücretsiz (private repo); public repoda sınırsız.
  Her 5 dakikada ~10 sn çalışan worker bunu rahatça karşılar.
- Auth: 50K aktif kullanıcı/ay ücretsiz.

## Bilinen Sınırlamalar / Notlar
- No-show görseli base64 büyükse FCM data limitine (4KB) takılır; bu durumda
  sadece metin bildirim gider. Küçük/ikonik görsel kullan.
- GitHub cron min. aralık ~5 dakika; "tam saniyesinde" bildirim beklenmemeli.
  İstemci-taraflı temizlik, host uygulamayı açınca anında devreye girer.
- Çok büyürse (binlerce kullanıcı) Firestore okuma limitleri zorlanır; o noktada
  Supabase'e geçiş veya Blaze düşünülebilir. Hobi ölçeği için gerek yok.
