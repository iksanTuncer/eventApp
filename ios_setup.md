# iOS Yapılandırma Notları

`flutter create` sonrası aşağıdakileri yap.

## 1. ios/Runner/Info.plist

`<dict>` içine ekle (izin açıklamaları zorunlu, yoksa app reddedilir):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Etkinlik konumunu işaretlemek için konumunuza erişiyoruz.</string>
<key>NSCameraUsageDescription</key>
<string>Profil ve etkinlik fotoğrafı çekmek için kamera erişimi.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Fotoğraf seçmek için galeri erişimi.</string>
```

## 2. GoogleService-Info.plist
Firebase Console > iOS uygulaması ekle > indirilen `GoogleService-Info.plist`'i
Xcode ile `Runner` hedefine ekle (sürükle-bırak, "Copy items if needed" işaretli).

## 3. Push Bildirim (FCM) — iOS özel
- Apple Developer hesabı gerekir (push için zorunlu).
- Xcode > Runner > Signing & Capabilities > "Push Notifications" capability ekle.
- "Background Modes" > "Remote notifications" işaretle.
- Apple Developer'da bir APNs Authentication Key (.p8) oluştur.
- Firebase Console > Proje Ayarları > Cloud Messaging > APNs key'i yükle.
- ÖNEMLİ: Push bildirimi iOS SİMÜLATÖRDE çalışmaz, fiziksel cihaz gerekir.

## 4. Harita (Google Maps GEREKMİYOR)
Uygulama haritayı `flutter_map` + OpenStreetMap ile gösterir → **API key / SDK
yapılandırması GEREKMEZ**. AppDelegate'e GMSServices eklemeyin. Tek gereksinim
internet erişimidir (zaten var). Eski "Google Maps" notları geçersizdir.

## 5. Minimum iOS sürümü
`ios/Podfile` içinde `platform :ios, '15.0'` (güncel Firebase iOS SDK için).
Podfile `pod install`/`flutter build` ile üretilir; satır yorumdaysa açıp ayarla.
