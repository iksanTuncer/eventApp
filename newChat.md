# 🔁 Yeni Sohbet Başlangıç Mesajı (Mac'te yapıştır)

> Eve gidince Mac mini'de yeni bir Claude Code sohbeti aç ve **aşağıdaki bloğu**
> ilk mesaj olarak yapıştır. Hem seni hem Claude'u tam kaldığımız yere getirir.
> Detaylı adımlar: **IOS_BUILD_GUIDE.md**

---

```
Merhaba, EventApp projesine Mac mini'den iOS derlemesi için devam ediyoruz.

DURUM / NEREDE KALDIK:
- Flutter + Firebase (ücretsiz Spark, kartsız) etkinlik davet uygulaması. Android APK çalışıyor.
- Push backend hazır ve çalışıyor: client → Firestore 'notifications' → GitHub Actions worker → FCM.
  GitHub'ın kendi cron'u güvenilmezdi; cron-job.org her dakika worker'ı tetikliyor (kuruldu, 204 OK, doğrulandı).
- "Kaçırdıklarım" ekranı, tıklanabilir harita (maps'te açılıyor), RSVP "Cevap" etiketi eklendi.
- iOS kod tarafı HAZIR: firebase_options.dart iOS'u içeriyor, Info.plist izinleri+push var,
  bundle id com.eventapp.eventApp, AppDelegate standart. Repoda commit'li.

ŞİMDİ YAPACAĞIMIZ: Mac'te iOS derlemesi + iPhone'da push testi.
Adım adım rehber repoda: IOS_BUILD_GUIDE.md (lütfen onu referans al).

ELİMDE HAZIR OLANLAR: Mac mini, Xcode, aktif Apple Developer hesabı.

KRİTİK 2 NOKTA (rehberde):
1) ios/Runner/GoogleService-Info.plist gitignore'da → clone'la gelmez.
   flutterfire configure --project eventapp-78a1f ile yeniden üreteceğiz.
2) iOS push için Apple'dan APNs .p8 anahtarı üretip Firebase Cloud Messaging'e yükleyeceğiz.

SABİTLER:
- Firebase proje: eventapp-78a1f
- Bundle ID: com.eventapp.eventApp
- GitHub: https://github.com/iksanTuncer/eventApp (public)
- E-posta: xantncr@gmail.com
- Kural: APK'yı sadece ben "derle" deyince derle.

Hadi Mac'te BÖLÜM 1'den (ortam kurulumu) başlayalım. İlk olarak ne yapmalıyım?
```

---

## Notlar
- Mac'teki Claude Code, bu Windows oturumunun hafızasını otomatik taşımaz.
  Bu yüzden yukarıdaki mesaj + repodaki `IOS_BUILD_GUIDE.md` birlikte "hafıza" görevi görür.
- Mac'te `git clone https://github.com/iksanTuncer/eventApp.git` yapınca bu dosya ve rehber gelir.
- Tek istisna: `GoogleService-Info.plist` (gitignore'da) + APNs `.p8` anahtarı → rehberde Bölüm 2.2 ve 3.
