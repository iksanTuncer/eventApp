# 🍎 EventApp — iOS Derleme Rehberi (Mac mini)

> Bu rehber, uygulamayı Mac'te derleyip iPhone'da (push dahil) test etmen için
> uçtan uca adımları içerir. **Android tarafı zaten çalışıyor**; burası yalnızca iOS.
>
> - **Bundle ID:** `com.eventapp.eventApp`
> - **Firebase proje:** `eventapp-78a1f`
> - **GitHub:** `https://github.com/iksanTuncer/eventApp` (public)
> - **Uygulama adı:** EventApp

---

## ✅ BÖLÜM 0 — Zaten HAZIR olanlar (kod tarafı, benim hallettiklerim)

Bunlar repoda commit'li, tekrar yapman GEREKMİYOR:

- [x] `lib/firebase_options.dart` → iOS yapılandırması mevcut (appId + `iosBundleId: com.eventapp.eventApp`)
- [x] `ios/Runner/Info.plist` → tüm izin metinleri hazır:
  - Konum (`NSLocationWhenInUseUsageDescription`)
  - Kamera (`NSCameraUsageDescription`)
  - Galeri (`NSPhotoLibraryUsageDescription`)
  - Arka plan push (`UIBackgroundModes → remote-notification`)
  - Uygulama adı `CFBundleDisplayName = EventApp`
- [x] `ios/Runner.xcodeproj` → `PRODUCT_BUNDLE_IDENTIFIER = com.eventapp.eventApp` (Firebase ile eşleşiyor)
- [x] `ios/Runner/AppDelegate.swift` → standart Flutter (FCM otomatik çalışır, değişiklik gerekmez)
- [x] Bildirim izni kod içinde isteniyor (`NotificationService.init`)
- [x] Push backend (cron-job.org + GitHub Actions) çalışıyor — iOS'a da gönderir

> ⚠️ **Tek eksik dosya:** `ios/Runner/GoogleService-Info.plist` **gitignore'da** olduğu için
> `git clone` ile Mac'e GELMEZ. Bölüm 2'de bunu çözüyoruz.

---

## 🧰 BÖLÜM 1 — Mac ortam kurulumu (bir kerelik)

### 1.1 Xcode
1. **App Store** → "Xcode" ara → indir (büyük, ~10–15 GB, sabırlı ol).
2. Xcode'u **bir kez aç** → lisansı kabul et → ek bileşenleri kurmasına izin ver.
3. Terminal'de komut satırı araçları:
   ```bash
   xcode-select --install
   sudo xcodebuild -license accept
   ```

### 1.2 Homebrew (yoksa)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.3 Flutter (Mac'e)
```bash
brew install --cask flutter
# veya manuel: https://docs.flutter.dev/get-started/install/macos
flutter --version
```

### 1.4 CocoaPods (iOS bağımlılıkları için)
```bash
sudo gem install cocoapods
# Apple Silicon'da sorun olursa: brew install cocoapods
pod --version
```

### 1.5 Apple Silicon (M1/M2/M3/M4) ise Rosetta
```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

### 1.6 Doğrulama
```bash
flutter doctor
```
`[✓] Xcode`, `[✓] CocoaPods` görmelisin. Eksik varsa `flutter doctor` ne yapacağını söyler.

---

## 📦 BÖLÜM 2 — Projeyi Mac'e alma + eksik Firebase dosyası

### 2.1 Repoyu klonla
```bash
cd ~/Desktop
git clone https://github.com/iksanTuncer/eventApp.git
cd eventApp
flutter pub get
```

### 2.2 Eksik `GoogleService-Info.plist` (iki yoldan biri)

**Yol A — flutterfire ile yeniden üret (ÖNERİLEN, en temiz):**
```bash
npm install -g firebase-tools          # yoksa
firebase login                         # tarayıcıda Google ile giriş (xantncr@gmail.com)
dart pub global activate flutterfire_cli
flutterfire configure --project eventapp-78a1f
```
- Platform seçiminde **iOS (ve Android)** işaretli olsun.
- Bu komut `firebase_options.dart`'ı tazeler ve `ios/Runner/GoogleService-Info.plist`'i yerine koyar.

**Yol B — Windows'tan dosyayı kopyala:**
- Windows'taki `C:\Users\iksantuncer\Desktop\eventApp\ios\Runner\GoogleService-Info.plist`
  dosyasını (USB/WhatsApp/Drive ile) Mac'te aynı yola koy:
  `~/Desktop/eventApp/ios/Runner/GoogleService-Info.plist`

---

## 🔑 BÖLÜM 3 — APNs Push Anahtarı (iOS push için ZORUNLU)

iOS'ta FCM'in push gönderebilmesi için Apple'dan bir **APNs Auth Key (.p8)** üretip
Firebase'e yüklemen gerekir. (Android'de bu gerekmiyordu; iOS'a özel.)

### 3.1 Apple'da .p8 anahtarı üret
1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles**
2. Sol menü **Keys** → **+** (yeni anahtar)
3. **Key Name:** `EventApp APNs`
4. **Apple Push Notifications service (APNs)** kutusunu işaretle → **Continue** → **Register**
5. **Download** ile `.p8` dosyasını indir → ⚠️ **YALNIZCA BİR KEZ indirilir, güvenli sakla.**
6. Şu iki değeri not al:
   - **Key ID** (anahtar sayfasında yazar, ör. `ABC123DEFG`)
   - **Team ID** (sağ üstte, üyelik sayfasında; ör. `1A2B3C4D5E`)

### 3.2 Firebase'e yükle
1. https://console.firebase.google.com → proje **eventapp-78a1f**
2. ⚙️ **Project settings** → **Cloud Messaging** sekmesi
3. **Apple app configuration** → iOS uygulaman (`com.eventapp.eventApp`) altında
   **APNs Authentication Key** → **Upload**
4. İndirdiğin **.p8** dosyasını seç, **Key ID** ve **Team ID**'yi gir → **Upload**

> Bu adım yapılmadan iOS'a push **gelmez** (Android etkilenmez).

---

## ✍️ BÖLÜM 4 — Xcode: imzalama + capability

```bash
cd ~/Desktop/eventApp
open ios/Runner.xcworkspace      # ⚠️ .xcworkspace AÇ, .xcodeproj DEĞİL!
```

Xcode açılınca:

1. Sol panelde **Runner** (en üst, mavi proje ikonu) → **TARGETS → Runner**
2. **Signing & Capabilities** sekmesi:
   - **Automatically manage signing** açık olsun
   - **Team:** kendi Apple Developer hesabını seç (xantncr@gmail.com)
   - **Bundle Identifier:** `com.eventapp.eventApp` (zaten dolu)
   - Hata kalmamalı (yeşil ya da uyarısız)
3. **+ Capability** (sol üst) → **Push Notifications** ekle
   - Bu, `Runner.entitlements` oluşturur ve App ID'de push'u etkinleştirir.
4. Tekrar **+ Capability** → **Background Modes** ekle → **Remote notifications** kutusunu işaretle.

---

## 🛠️ BÖLÜM 5 — Pod kurulumu + iPhone'da çalıştırma

### 5.1 Pod install
```bash
cd ~/Desktop/eventApp/ios
pod install
cd ..
```
- "platform" hatası alırsan: `ios/Podfile` dosyasında en üstteki satırı aç/güncelle:
  ```ruby
  platform :ios, '15.0'
  ```
  sonra tekrar `cd ios && pod install && cd ..`.

### 5.2 iPhone'u hazırla (push GERÇEK cihazda çalışır, simülatörde ÇALIŞMAZ)
1. iPhone'u USB ile bağla → "Bu bilgisayara güven" → **Güven**.
2. iPhone'da **Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu** → **Aç** → telefonu yeniden başlat.
3. Cihazı doğrula:
   ```bash
   flutter devices
   ```
   iPhone'un listede görünmeli.

### 5.3 Çalıştır
```bash
flutter run --release
```
- İlk açılışta iPhone "güvenilmeyen geliştirici" diyebilir:
  **Ayarlar → Genel → VPN ve Cihaz Yönetimi** → geliştirici profilini **Güven**.
- Uygulama açılınca bildirim izni sorusuna **İzin Ver** de (push için şart).

---

## 🔔 BÖLÜM 6 — Push testi

1. iPhone'da giriş yap (bildirim iznini verdiğinden emin ol).
2. Başka bir hesaptan (veya Android cihazdan) bu iPhone kullanıcısını **etkinliğe davet et**.
3. **~1 dakika içinde** iPhone'a push düşmeli (cron-job.org her dakika tetikliyor).

Push gelmezse Bölüm 7'deki kontrol listesine bak.

> Worker'ın gönderip göndermediğini Windows'tan ben doğrulayabiliyorum:
> loglarda `Invite sent for event ... -> N tokens` satırı çıkıyor.

---

## 🚀 BÖLÜM 7 — (İsteğe bağlı) TestFlight / App Store

WhatsApp'tan APK dağıtır gibi iOS'ta doğrudan dosya paylaşılamaz; **TestFlight** kullanılır:

1. https://appstoreconnect.apple.com → **Apps → +** → yeni uygulama, bundle `com.eventapp.eventApp`.
2. Xcode → **Product → Archive** → **Distribute App → App Store Connect → Upload**.
3. App Store Connect → **TestFlight** → test kullanıcısı (e-posta) ekle → onlar TestFlight uygulamasından kurar.

(İlk kez App Store'a public yayın için Apple inceleme süreci + gizlilik formları gerekir.)

---

## 🧩 İsteğe bağlı: iOS launcher ikonu

Özel ikonun iOS'ta da çıkması için (Android'de zaten var):
```bash
dart run flutter_launcher_icons
```

---

## 🆘 Sık karşılaşılan sorunlar

| Sorun | Çözüm |
|-------|-------|
| "Signing requires a development team" | Signing & Capabilities → **Team** seç |
| `pod install` çok yavaş/hata | `pod repo update` sonra tekrar `pod install` |
| Push gelmiyor (iOS) | APNs `.p8` Firebase'e yüklü mü? **Gerçek cihaz** mı? Geliştirici Modu açık mı? Bildirim izni verildi mi? |
| Uygulama açılmıyor "untrusted developer" | Ayarlar → Genel → VPN ve Cihaz Yönetimi → **Güven** |
| `flutter doctor` Xcode/CocoaPods kırmızı | Çıkan komutu uygula (genelde `xcode-select --install` / `sudo gem install cocoapods`) |
| Workspace yerine project açtım, hata | Mutlaka `Runner.xcworkspace` aç |
| Apple Silicon pod mimari hatası | `arch -x86_64 pod install` (nadiren gerekir) |

---

## 📋 Hızlı özet (kopyala-yapıştır sıra)

```bash
# 1) Ortam (bir kerelik): Xcode (App Store), sonra:
xcode-select --install
sudo gem install cocoapods

# 2) Proje
cd ~/Desktop
git clone https://github.com/iksanTuncer/eventApp.git
cd eventApp
flutter pub get

# 3) Eksik Firebase iOS dosyası
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project eventapp-78a1f   # iOS + Android seç

# 4) APNs anahtarı: Apple Developer'da .p8 üret → Firebase Cloud Messaging'e yükle (Bölüm 3)

# 5) Xcode imzalama + capability
open ios/Runner.xcworkspace
#   -> Team seç, Push Notifications + Background Modes(Remote notifications) ekle

# 6) Pod + çalıştır
cd ios && pod install && cd ..
flutter run --release        # iPhone bağlı + Geliştirici Modu açık
```

İyi çalışmalar! ☕ Takıldığın adımda bana ekran görüntüsüyle sor.
