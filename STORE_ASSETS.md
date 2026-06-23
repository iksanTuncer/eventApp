# STORE_ASSETS.md — Mağaza Görselleri ve Metinleri

EventApp — sıcak içecek temalı etkinlik daveti uygulaması.
Bu dosya: (A) Play Store + App Store için **nano banana (Gemini Image) promptları**
ve (B) hazır **mağaza metinleri** içerir.

> **Marka paleti:** sıcak kahve tonları — espresso kahvesi `#6F4E37`, krem
> `#F3E9DD`, açık bej `#E0D5C5`, koyu kahve `#4A2F1B`. Tema sıcak, samimi,
> minimal, modern.
> **Uygulama adı:** EventApp · **Tagline:** "Bir fincan kahveye buluşalım"

---

## ÖNEMLİ — nano banana kullanım notları

- nano banana = **Gemini 2.5 Flash Image**. Prompt'a **tam çıktı boyutunu** ve
  "no text" / "exact text" talimatını net yaz.
- Üstüne yazı isteyeceğin görsellerde Türkçe karakter (ç, ş, ğ, ı, ö, ü) bazen
  hatalı çıkar. **En garantili yöntem:** görseli yazısız üret, yazıyı sonradan
  Canva/Figma ile ekle. Yine de aşağıda yazılı promptları da veriyorum.
- Üretilen görseli mağaza spesifik boyutuna **birebir** kırp/yeniden boyutlandır
  (boyutlar yanlışsa mağaza reddeder).

---

# BÖLÜM A — GÖRSELLER (nano banana promptları)

## A1. Uygulama İkonu

**Gerekli boyutlar:** Play Store 512×512 PNG (alpha olabilir) · App Store
1024×1024 PNG (**alpha/şeffaflık YOK, köşe yuvarlama YOK** — Apple kendisi yapar).

> Tek görsel üret (1024×1024), Play için 512'ye küçült.

**Prompt:**
```
A modern, minimalist mobile app icon, 1024x1024 pixels, square format.
Centered illustration of a steaming coffee cup viewed from a slight top angle,
with a small location pin / map marker subtly forming the rising steam.
Flat design, smooth gradients, warm coffee color palette: espresso brown
(#6F4E37), cream (#F3E9DD), light beige (#E0D5C5). Soft warm background,
gentle radial glow. Clean, friendly, premium feel. No text, no letters,
no words. Crisp edges, high detail, app-store quality, fully opaque
background (no transparency).
```

## A2. Play Store — Öne Çıkan Görsel (Feature Graphic)

**Gerekli boyut:** 1024×500 PNG/JPG, **şeffaflık YOK**. Ortadaki metin/logoyu
kenarlara çok yaklaştırma (Play bazen üstüne yazı bindiriyor).

**Prompt:**
```
A horizontal banner, exactly 1024x500 pixels, for a coffee-themed event
invitation app. Left side: a warm flat-style illustration of two friends
toasting coffee cups at a cozy cafe table, steam rising. Right side: clean
empty space with soft cream background for app name overlay. Warm coffee
palette: espresso brown (#6F4E37), cream (#F3E9DD), beige (#E0D5C5). Soft
shadows, modern flat illustration, inviting and friendly mood. No text.
```
> Üretildikten sonra sağ boşluğa **"EventApp"** ve alt satıra
> **"Bir fincan kahveye buluşalım"** yazısını Canva/Figma ile ekle.

## A3. Telefon Ekran Görüntüleri (Promo / Screenshot)

**Gerekli boyutlar:**
- **Play Store:** en az 2, en fazla 8. 9:16, örn **1080×1920** PNG.
- **App Store (zorunlu):** iPhone 6.9"/6.7" → **1290×2796**. (6.5" → 1242×2688
  istenirse aynı tasarımı yeniden boyutlandır.)

> En temiz yöntem: **emülatörden gerçek ekran görüntüsü** al (uygulamayı çalıştır,
> her ekranı çek) ve aşağıdaki başlık metinlerini üstüne mockup şablonuyla ekle.
> Tamamen yapay üretmek istersen aşağıdaki nano banana promptlarını kullan.

Her görsel için ortak çerçeve prompt'u (telefon mockup + başlık):
```
A vertical app-store screenshot, exactly 1080x1920 pixels. Top third: a short
marketing headline on a warm cream (#F3E9DD) background. Bottom two-thirds: a
realistic smartphone mockup (front view, slight tilt) showing the app screen
described below. Warm coffee palette, espresso brown (#6F4E37) accents, soft
drop shadow under the phone, clean modern look.
```

**Görsel 1 — Davet gönder**
- Başlık (üste ekle): **"Sevdiklerini kahveye davet et"**
- Telefon ekranı prompt eki:
```
The phone screen shows an event creation screen: a coffee cup hero image at
top, fields for date/time and location, and a list of friends with checkboxes
to invite, plus a brown "Davetleri Gönder" button.
```

**Görsel 2 — Katılım durumu**
- Başlık: **"Kim geliyor, kim gelmiyor — tek bakışta"**
- Ekran eki:
```
The phone screen shows an event detail screen with three sections:
"Katılacaklar", "Katılmayacaklar", "Yanıt bekleniyor", each listing user
avatars and names. Warm beige cards, brown headings.
```

**Görsel 3 — Bildirimler**
- Başlık: **"Davet anında haberin olsun"**
- Ekran eki:
```
The phone screen shows a home screen with two tabs "Davetlerim" and
"Etkinliklerim", a push notification banner at the top reading a coffee
invitation. Warm coffee themed cards with cup images.
```

**Görsel 4 — Kaçırdıklarım**
- Başlık: **"Kaçırdığın buluşmaları kaçırma"**
- Ekran eki:
```
The phone screen shows a "Kaçırdıklarım" list: cards each with a coffee event
image and a short message, a small "Kaldır" button. Cozy, nostalgic warm tone.
```

## A4. (Opsiyonel) iPad / Tablet Görselleri
İlk sürümde iPad'i opsiyonel bırakabilirsin. iPad'i App Store'da
desteklemiyorsan iPad screenshot'ı **gerekmez** (App Store Connect'te
"iPad" cihaz ailesini kapalı tut). Play tablet görselleri de opsiyoneldir.

---

# BÖLÜM B — MAĞAZA METİNLERİ (kopyala-yapıştır)

## B1. Ortak

- **Uygulama adı (görünen):** EventApp
- **Kategori:** Sosyal (Social) / Yaşam Tarzı (Lifestyle)
- **İçerik derecesi:** Herkes / 4+
- **Gizlilik Politikası URL'si (ZORUNLU):** _Bir URL hazırlaman gerekiyor._
  GitHub Pages veya basit bir Notion/Google Sites sayfası yeterli. (Aşağıda B6'da
  taslak metin var.)

## B2. Play Store

**Uygulama adı (maks 30 karakter):**
```
EventApp — Kahve Daveti
```

**Kısa açıklama (maks 80 karakter):**
```
Sevdiklerini kahveye davet et, katılımları gör, kimse kaçırmasın.
```

**Tam açıklama (maks 4000 karakter):**
```
EventApp, sıcak içecek buluşmaları için tasarlanmış sade ve samimi bir
davet uygulamasıdır. Filtre kahve, çay, Türk kahvesi ya da soğuk bir içecek;
sevdiklerini birkaç dokunuşla davet et, kimlerin geleceğini anında gör.

• Etkinlik oluştur
Hazır içecek tiplerinden birini seç (Filtre Kahve, Çay, Soğuk İçecek, Türk
Kahvesi) ya da "Diğer" ile kendi etkinliğini özgürce tasarla. Başlangıç ve
bitiş saatini belirle, konumu haritadan işaretle veya metin olarak yaz.

• Davet et
Kişi listenden dilediklerini seç, davetler anında bildirim olarak gider.
Davetliler "Katılacağım" ya da "Katılmayacağım" diyerek yanıtlar.

• Katılımı takip et
Etkinlik detayında katılacaklar, katılmayacaklar ve henüz yanıt vermeyenler
ayrı ayrı listelenir. Kim geliyor, tek bakışta görürsün.

• Kaçırdıklarım
Etkinlik bittiğinde gelemeyenlere özel bir mesaj ve görsel gönderilir.
"Kaçırdıklarım" bölümünde bu anılar seni bekler.

• Sade ve hızlı
Reklam yok, karmaşa yok. Sıcacık bir tasarım ve tek amaç: insanları bir
araya getirmek.

Bir fincan kahve, bin sohbet. EventApp ile buluşmak çok kolay.
```

**Yeni sürüm notları (What's new — 1.0.0):**
```
İlk sürüm! Etkinlik oluştur, davet gönder, katılımları takip et ve
buluşmalarını kaçırma.
```

## B3. App Store

**Uygulama adı (maks 30 karakter):**
```
EventApp — Kahve Daveti
```

**Alt başlık / Subtitle (maks 30 karakter):**
```
Kahveye davet et, buluş
```

**Tanıtım metni / Promotional Text (maks 170 karakter):**
```
Sevdiklerini bir fincan kahveye davet et, kimlerin geleceğini anında gör.
Sade, sıcak ve reklamsız buluşma uygulaması.
```

**Açıklama / Description (App Store):**
```
EventApp, sıcak içecek buluşmaları için tasarlanmış sade ve samimi bir
davet uygulamasıdır. Filtre kahve, çay, Türk kahvesi ya da soğuk bir içecek;
sevdiklerini birkaç dokunuşla davet et, kimlerin geleceğini anında gör.

ETKİNLİK OLUŞTUR
Hazır içecek tiplerinden birini seç ya da "Diğer" ile kendi etkinliğini
tasarla. Başlangıç–bitiş saatini belirle, konumu haritadan işaretle veya
metin olarak gir.

DAVET ET
Kişi listenden dilediklerini seç; davetler anında bildirim olarak gider.
Davetliler katılım durumlarını tek dokunuşla bildirir.

KATILIMI TAKİP ET
Katılacaklar, katılmayacaklar ve yanıt bekleyenler ayrı ayrı listelenir.

KAÇIRDIKLARIM
Bittiğinde gelemeyenlere özel mesaj ve görsel gönderilir; bu anılar
"Kaçırdıklarım" bölümünde saklanır.

Reklam yok, karmaşa yok. Bir fincan kahve, bin sohbet.
```

**Anahtar kelimeler / Keywords (maks 100 karakter, virgülle):**
```
kahve,davet,etkinlik,buluşma,çay,arkadaş,toplantı,rsvp,sosyal,plan
```

**Yeni sürüm notu (1.0.0):**
```
İlk sürüm. Etkinlik oluştur, davet gönder, katılımları takip et.
```

## B4. App Store — İnceleme (Review) Bilgileri

App Store inceleme ekibi için (App Store Connect → App Review Information):
- **Demo hesap:** Gözden geçirme test hesabı bilgilerini buraya gir
  (e-posta + şifre). _Repoya yazma_ — sadece App Store Connect formuna.
- **Notlar (Notes) önerisi:**
```
Bu, e-posta/şifre ile giriş yapılan bir davet uygulamasıdır. Lütfen verilen
demo hesabıyla giriş yapın. İki cihaz/iki hesap gerektiren akışlar (davet
gönderme→yanıt) için ikinci bir hesap da oluşturabilirsiniz. Konum izni yalnızca
etkinlik konumunu haritadan işaretlemek için, uygulama açıkken kullanılır.
Bildirimler etkinlik davetleri içindir.
```

## B5. Veri Gizliliği Beyanı (Data Safety / App Privacy) — özet

Her iki mağaza da "hangi veriyi topluyorsun" diye sorar. EventApp için:
- **Toplanan:** E-posta adresi (kimlik doğrulama), kullanıcı adı, profil
  fotoğrafı (opsiyonel), oluşturulan etkinlik verisi, cihaz bildirim token'ı (FCM).
- **Konum:** Yalnızca kullanıcı haritadan işaretlerse, **yaklaşık/kesin konum
  noktası etkinlik içinde** saklanır; arka planda toplanmaz.
- **Üçüncü taraf:** Firebase (Authentication, Firestore, Cloud Messaging).
- **Reklam / takip:** Yok.
- **Hesap silme:** Uygulama içinden hesap ve tüm veriler kalıcı silinebilir
  (App Store/Play "hesap silme" gereği karşılanıyor).

## B6. Gizlilik Politikası — taslak metin (bir sayfada yayınla)

```
Gizlilik Politikası — EventApp

EventApp ("uygulama"), sıcak içecek etkinlikleri için bir davet
uygulamasıdır. Bu politika hangi verileri topladığımızı ve nasıl
kullandığımızı açıklar.

Toplanan veriler:
- E-posta adresi ve şifre (Firebase Authentication ile kimlik doğrulama).
- Kullanıcı adı ve opsiyonel profil fotoğrafı.
- Oluşturduğun etkinlikler, davetler ve katılım yanıtları.
- Bildirim göndermek için cihaz bildirim anahtarı (FCM token).
- Etkinlik için haritadan işaretlersen konum noktası (yalnızca o etkinlikte).

Kullanım: Veriler yalnızca uygulamanın çalışması (davet, bildirim, katılım
takibi) için kullanılır. Reklam göstermiyoruz, veriyi satmıyoruz.

Saklama ve silme: Süresi geçen etkinlikler ve ilgili veriler otomatik silinir.
Uygulama içinden hesabını ve tüm verilerini kalıcı olarak silebilirsin.

Altyapı: Google Firebase (Authentication, Cloud Firestore, Cloud Messaging).

İletişim: <buraya bir e-posta adresi ekle>
```

> Bu metni GitHub Pages / Google Sites / Notion'da yayınla ve URL'sini her iki
> mağaza formuna gir. **`<buraya bir e-posta>`** kısmını doldurmayı unutma.

---

## Hızlı checklist (mağaza yükleme)

**Play Store:**
- [ ] İkon 512×512
- [ ] Feature graphic 1024×500
- [ ] En az 2 telefon screenshot (1080×1920)
- [ ] Kısa + tam açıklama (B2)
- [ ] Data safety formu (B5)
- [ ] Gizlilik politikası URL (B6)

**App Store:**
- [ ] İkon 1024×1024 (şeffaflıksız)
- [ ] iPhone 6.7"/6.9" screenshot (1290×2796) — en az 1 (3+ önerilir)
- [ ] Subtitle + açıklama + keywords (B3)
- [ ] App Privacy formu (B5)
- [ ] App Review demo hesap + notlar (B4)
- [ ] Gizlilik politikası URL (B6)
