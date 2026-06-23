# fix.md — Düzeltmeler ve Senin Yapman Gerekenler

Bu dosya, 2026-06-23 tarihinde yapılan 3 düzeltmeyi ve **senin Apple/Firebase
tarafında yapman gereken** adımları içerir. Kod tarafı bende tamamlandı; aşağıda
"SENİN YAPMAN GEREKEN" başlıkları senin elle yapacağın işler.

---

## 1) Android — Yeni kayıt sırasında "Devam" tuşu çalışmıyordu ✅ (kod düzeltildi)

**Sebep:**
- `UserService.updateProfile` Firestore'a `.update()` ile yazıyordu. `.update()`
  döküman yoksa **hata fırlatır**. Kayıt anında profil dökümanı bazen
  oluşmamış olabiliyor → yazma patlıyordu.
- `profile_screen._save()` ve `interests_screen._finish()` içinde `try/finally`
  vardı ama **`catch` yoktu**. Hata sessizce yutuluyor, buton tekrar aktif
  oluyor ama hiçbir şey olmuyordu (kullanıcı "çalışmıyor" diyor).

**Yapılan:**
- `updateProfile` artık `set(data, SetOptions(merge: true))` kullanıyor →
  döküman olsa da olmasa da güvenli (idempotent) yazıyor.
- Her iki onboarding ekranına `catch` + SnackBar eklendi (`S.saveFailed`):
  bir hata olursa kullanıcı artık görüyor.

**SENİN YAPMAN GEREKEN:** Yok. `git pull` + yeni APK/AAB build yeterli.

---

## 2) Davetlerim / Etkinliklerim / Kaçırdıklarım boş görünüyordu ✅ (kod) + ⚠️ (senin adımın)

**Sebep:**
- `home_screen` ve `missed_screen` içindeki `StreamBuilder`'lar `snap.data ?? []`
  yapıyordu. Sorgu **hata** verdiğinde bu, sessizce **boş liste** gibi
  gösteriliyordu.
- `invitedEvents` ve `hostedEvents` sorguları **composite index** gerektirir
  (`inviteeUids + endAt`, `hostUid + endAt`). Bu index'ler Firebase'e
  **deploy edilmemişse** sorgu hata verir → liste boş görünür.

**Yapılan (kod):**
- Üç `StreamBuilder`'a `snap.hasError` kontrolü eklendi. Artık hata olursa
  "Veriler yüklenemedi" mesajı çıkıyor (sessiz boşluk yerine).

**SENİN YAPMAN GEREKEN (ÖNEMLİ — index deploy):**

`firestore/firestore.indexes.json` ve kuralları Firebase'e deploy et:

```bash
# Firebase CLI kuruluysa:
firebase deploy --only firestore:indexes,firestore:rules
```

> Firebase CLI yoksa: `npm install -g firebase-tools` → `firebase login` →
> proje kökünde `firebase use <proje-id>` → yukarıdaki komut.

Alternatif (tek tek elle): Uygulamayı debug modda çalıştır, "Davetlerim"
sekmesini aç. Index eksikse **logcat / konsolda** şuna benzer bir hata + bir
**link** çıkar:

```
[cloud_firestore/failed-precondition] The query requires an index. You can
create it here: https://console.firebase.google.com/...
```

O linke tıklayıp "Create Index" demen, index'i otomatik oluşturur (deploy ile
aynı sonuç). Index oluşması birkaç dakika sürebilir.

**Not:** Etkinlikler bitiş zamanı (`endAt`) geçince cron tarafından otomatik
siliniyor. Test ederken **bitiş zamanı gelecekte** olan etkinlik oluştur, yoksa
liste doğal olarak boş kalır.

---

## 3) Apple uyarısı 90683 — "Missing purpose string in Info.plist" ✅ (kod düzeltildi)

**Apple'ın uyarısı:** `Info.plist`'te `NSLocationAlwaysAndWhenInUseUsageDescription`
anahtarı eksik. Kullandığımız `geolocator` eklentisi, "Always" konum
yetkilendirme API'sine **referans verdiği** için Apple bu anahtarı istiyor
(biz sadece "uygulama açıkken" konum kullansak bile).

**Yapılan:** `ios/Runner/Info.plist`'e eklendi:
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription` (eski iOS için)

**SENİN YAPMAN GEREKEN:**
1. `git pull`
2. Yeni iOS build al (Xcode veya CI) ve App Store Connect'e tekrar yükle.
   - macOS'ta: `flutter build ipa` → `Runner.xcworkspace` → Archive → Upload.
3. Yeni build'de bu uyarı çıkmamalı. (Uyarı build'i engellemez ama temiz olması iyi.)

---

## Özet checklist (senin yapacakların)

- [ ] `git pull` (bu düzeltmeleri çek)
- [ ] **Firestore index + rules deploy** (Madde 2) — bu, boş liste sorununun ASIL çözümü
- [ ] Android: yeni AAB build → Play Console internal test
- [ ] iOS: yeni build → App Store Connect (90683 uyarısı kalkmış olmalı)
- [ ] Test: gelecekte biten bir etkinlik oluştur, davet et, listede görünüyor mu kontrol et

Mağaza görselleri ve metinleri için bkz: `STORE_ASSETS.md`
