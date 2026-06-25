# MAC_CLAUDE_HANDOFF.md — Mac'te Claude Code için Proje Devir Notu

> Bu dosya, **Mac mini'de Claude Code** ile çalışmaya devam etmek için hazırlandı.
> Mac'te yeni bir Claude oturumu açtığında bu dosyayı ona oku/göster; tüm proje
> bağlamı, kurallar ve kaldığımız yer burada. (Windows + Mac aynı GitHub reposunu
> paylaşıyor; tek doğruluk kaynağı `git`.)

---

## 0) Claude'a ilk mesaj (kopyala-yapıştır)

> "Bu Flutter projesinde Windows'ta başladık, şimdi Mac'te devam ediyoruz.
> `MAC_CLAUDE_HANDOFF.md`, `CLAUDE.md` ve `fix.md` dosyalarını oku. Özellikle
> `endAt > now` değişmezine, ücretsiz Firebase kurallarına (Storage/Functions YOK)
> ve `services/` soyutlamasına uy. Değişiklikten sonra `flutter analyze` çalıştır."

---

## 1) Proje özeti

- **Ne:** Sıcak içecek (kahve/çay) etkinlikleri için davet uygulaması. Flutter
  (Dart), tek kod tabanı Android + iOS. Arayüz **Türkçe**, kod/yorum İngilizce/Türkçe.
- **Backend:** Firebase **ÜCRETSİZ Spark planı** (kredi kartı YOK).
  - ❌ Firebase Storage YOK → fotoğraflar sıkıştırılıp **base64** olarak Firestore'a.
  - ❌ Firebase Cloud Functions YOK → süre kontrolü/silme **cron** ile
    (`scripts/cron_worker.js`, GitHub Actions / cron-job.org, Admin SDK).
  - Auth: Email+Password · DB: Cloud Firestore · Push: FCM.
- Ayrıntılı proje kuralları: **`CLAUDE.md`** (oku).

## 2) Sabit kimlikler

| Şey | Değer |
|-----|-------|
| Firebase proje ID | `eventapp-78a1f` |
| iOS bundle id (GERÇEK) | `com.iksantuncer.eventApp` |
| Android applicationId | `com.eventapp.event_app` |
| GitHub | `https://github.com/iksanTuncer/eventApp` (public) |
| Sürüm (pubspec) | `1.0.0+2` |

> ⚠️ Firebase'de eski bir iOS app (`com.eventapp.eventApp`) var, KULLANILMIYOR.
> Tüm iOS işlemleri `com.iksantuncer.eventApp` altında.

## 3) Mimari / klasörler

```
lib/
  models/      app_user, app_event (Rsvp), missed_event
  services/    auth_service, auth_provider (ChangeNotifier), user_service,
               event_service, image_service, notification_service,
               notification_queue_service, location_service
  screens/     auth/, onboarding/(profile, interests), events/(type_picker,
               form, detail, invitee_picker, map_picker), home_screen,
               missed_screen, profile/edit_profile
  widgets/     event_card, image_source_sheet, static_map
  theme/       app_theme (kahve paleti)
  utils/       strings (TÜM Türkçe metinler), constants
firestore/     firestore.rules, firestore.indexes.json
scripts/       cron_worker.js (Admin SDK)
```

**Kurallar:**
- State: `provider`. Her Firestore erişimi **`services/` altında** soyutlanır
  (ekranlar doğrudan Firestore çağırmaz).
- Tüm Türkçe arayüz metinleri **`lib/utils/strings.dart`** (`S.xxx`).
- Her async çağrı try/catch + kullanıcıya SnackBar. (Sessiz hata YOK — bu projede
  sessiz yutulan hatalar gerçek buglara yol açtı.)
- Görsel: maks ~250KB, base64. `image_service.dart`.

## 4) "Davetlerim / Etkinliklerim / Kaçırdıklarım" tam olarak ne demek

Ana ekran artık **3 sekme** (bu sırada): **Davetlerim · Etkinliklerim · Kaçırdıklarım**.

| Sekme | Anlamı | Sorgu |
|-------|--------|-------|
| **Davetlerim** | **Başkalarının** beni davet ettiği, **aktif** (bitmemiş) etkinlikler. Host'lar burada KENDİ etkinliğini görmez. | `events` where `inviteeUids` arrayContains uid AND `endAt > now` |
| **Etkinliklerim** | **Benim oluşturduğum** (host), **aktif** etkinlikler. | `events` where `hostUid == uid` AND `endAt > now` |
| **Kaçırdıklarım** | Süresi geçince **silinen** ama benim katılmadığım (no/pending) etkinliklerin görsel+mesaj kaydı. Yalnızca **cron** yazar. | `users/{uid}/missed` orderBy `createdAt` desc |

**ÖNEMLİ DEĞİŞMEZ:** Bir etkinliğin "Davetlerim/Etkinliklerim"de görünmesi için
**`endAt` gelecekte olmalı**. `endAt` geçmişe düşerse: (1) sorgu onu hariç tutar,
(2) cron worker etkinliği **siler**. Bu yüzden tarih seçici end < start veya
end < now seçimine izin vermez (bkz. `event_form_screen._pickDateTime`).

## 5) Bu oturumda yapılanlar (Windows) — hepsi push'lu

1. **Onboarding "Devam" tuşu:** `UserService.updateProfile` artık `set(merge)`
   (eski `.update()` doküman yoksa patlıyordu). profile/interests ekranlarına
   `catch`+SnackBar.
2. **Boş listeler:** home/missed `StreamBuilder`'larına `hasError` kontrolü; ayrıca
   **Firestore index + rules deploy edildi** (`eventapp-78a1f`).
3. **Apple 90683:** `Info.plist`'e `NSLocationAlwaysAndWhenInUseUsageDescription`.
4. **Sürüm:** `1.0.0+2` (yeni TestFlight upload için).
5. **3 sekme + görünür sekme rengi:** Kaçırdıklarım üçüncü sekme oldu;
   `unselectedLabelColor` ayarlandı (kahve zeminde okunur).
6. **Tarih/saat seçici:** bitiş < başlangıç veya bitiş < şimdi engellendi;
   başlangıç ileri kayarsa bitiş sıfırlanır; `_validate()`'e gelecek-zaman kontrolü.

İlgili dosyalar: `lib/services/user_service.dart`, `lib/screens/onboarding/*`,
`lib/screens/home_screen.dart`, `lib/screens/missed_screen.dart`,
`lib/screens/events/event_form_screen.dart`, `lib/utils/strings.dart`,
`ios/Runner/Info.plist`. Mağaza metin/görselleri: `STORE_ASSETS.md`.

## 6) Komutlar (Mac)

```bash
# Bağımlılıklar / analiz
flutter pub get
flutter analyze lib/

# Android test build (imzalı release APK; android/key.properties gerekli)
flutter build apk --release          # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release    # Play için AAB

# iOS (Mac'e özel) — ortam kurulumu IOS_BUILD_GUIDE.md'de
cd ios && pod install && cd ..
open ios/Runner.xcworkspace          # Product → Archive → App Store Connect Upload
# veya:
flutter build ipa --release

# Fiziksel cihazda çalıştır
flutter run --release

# Firebase (yalnızca rules/indexes DEĞİŞİRSE)
firebase deploy --only firestore:indexes,firestore:rules --project eventapp-78a1f
```

> **Backend zaten deploy'lu.** Kuralları/index'leri değiştirmediğin sürece Mac'te
> Firebase deploy GEREKMEZ.

## 7) Mac'te dikkat / gotcha'lar

- **gitignore'da olup clone ile GELMEYEN dosyalar:** `lib/firebase_options.dart`
  ve `ios/Runner/GoogleService-Info.plist`. Daha önceki Mac build'inde varsa durur;
  yoksa: `flutterfire configure --project eventapp-78a1f` (iOS+Android seç).
- **iOS push** yalnızca **gerçek cihazda** + APNs `.p8` Firebase'e yüklüyse çalışır
  (detay `IOS_BUILD_GUIDE.md` Bölüm 3). Simülatörde push yok.
- **FCM token** her yeni kurulumda değişir; uygulamayı açıp giriş + bildirim izni
  verilince `users/{uid}/private/push`'a yazılır. Test öncesi HER cihazda aç+izin ver.
- **Firestore index build** birkaç dakika sürebilir; yeni index sonrası liste hemen
  dolmazsa 2-5 dk bekle.
- **App Store Connect** aynı build numarasını ikinci kez kabul etmez → her upload'da
  `pubspec.yaml` `version: 1.0.0+N` artır.
- **Test verisi:** etkinlik oluştururken **bitiş zamanı gelecekte** olsun; yoksa
  cron siler ve hiçbir sekmede görünmez (kullanıcı bunu "bug" sandı — aslında
  tarih seçici hatası geçmiş endAt'e izin veriyordu; düzeltildi).

## 8) Sıradaki işler (öneri)

- [ ] Bu son düzeltmeleri cihazda test et (3 sekme, tarih seçici, etkinlik görünür mü).
- [ ] iOS: `1.0.0+2` archive → App Store Connect (90683 uyarısı kalkmalı).
- [ ] Android: yeni AAB → Play Console internal test.
- [ ] Mağaza görselleri + metinleri (`STORE_ASSETS.md`), gizlilik politikası URL'si.

---

**Çalışma akışı (her iki makinede aynı):** `git pull` → değişiklik → `flutter analyze`
→ test → `git commit` → `git push`. Diğer makinede `git pull` ile devam.
