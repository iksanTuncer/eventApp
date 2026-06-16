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

> NOT: Google Maps API anahtarı GEREKMEZ. Uygulama haritayı `flutter_map` +
> OpenStreetMap ile gösterir (anahtarsız, ücretsiz). `com.google.android.geo.API_KEY`
> meta-data'sı EKLENMEZ. Eski Google Maps notları geçersizdir.

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

## 5. Harita (Google Maps GEREKMİYOR)
Uygulama haritayı `flutter_map` + OpenStreetMap ile çizer → **API key / SDK
yapılandırması yok**. Konum iki modu destekler: haritadan işaretle (OSM) veya
metin. Hiçbir Google Cloud Maps ayarı gerekmez.
