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

## 4. Google Maps (iOS)
- `ios/Runner/AppDelegate.swift` içine, `application` fonksiyonuna:
  ```swift
  GMSServices.provideAPIKey("BURAYA_GOOGLE_MAPS_API_KEY")
  ```
  ve üste `import GoogleMaps`.
- Google Cloud Console'da "Maps SDK for iOS"u etkinleştir.

## 5. Minimum iOS sürümü
`ios/Podfile` içinde `platform :ios, '13.0'` (Firebase için).
