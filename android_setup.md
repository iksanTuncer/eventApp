# Android Yapılandırma Notları

`flutter create` sonrası aşağıdaki düzenlemeleri yap.

## 1. android/app/src/main/AndroidManifest.xml

`<manifest>` içine, `<application>` üstüne izinleri ekle:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

Google Maps API anahtarını `<application>` içine ekle:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="BURAYA_GOOGLE_MAPS_API_KEY"/>
```

## 2. android/app/build.gradle (veya build.gradle.kts)

- `minSdkVersion` en az 23 (Firebase Auth için).
- Dosya sonuna: `apply plugin: 'com.google.gms.google-services'`

## 3. android/build.gradle

`dependencies` içine:
```gradle
classpath 'com.google.gms:google-services:4.4.2'
```

## 4. google-services.json

Firebase Console > Proje Ayarları > Android uygulaması ekle > indirilen
`google-services.json`'u `android/app/` içine koy.

## 5. Google Maps API Key (ÜCRETSİZ kotada)
- Google Cloud Console > APIs & Services > "Maps SDK for Android" etkinleştir.
- API key oluştur. Aylık ücretsiz kullanım kotası hobi için fazlasıyla yeter.
- Kartsız kullanmak istersen harita yerine sadece "metin konum" modunu kullan;
  uygulama iki modu da destekliyor.
