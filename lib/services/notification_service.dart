import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'user_service.dart';

/// Firebase Cloud Messaging (FCM) — tamamen ücretsiz.
///
/// ÖNEMLİ: FCM'de bir cihazdan diğerine doğrudan bildirim göndermek için
/// sunucu anahtarı gerekir; bunu istemciye GÖMME (güvenlik). Bu yüzden:
///  - Davet/no-show bildirimlerini GitHub Actions cron worker gönderir
///    (Firebase Admin SDK ile, scripts/cron_worker.js).
///  - Bu servis SADECE: token alma/kaydetme + gelen bildirimi gösterme yapar.
///  - Davet anında "hemen" bildirim için: ya cron worker'ı tetikleyen bir
///    bildirim-kuyruğu (notifications koleksiyonu) yazılır, cron işler;
///    ya da basit kullanım için davetli uygulamayı açınca davetini görür.
class NotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _userService = UserService();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;

  Future<void> init(String uid) async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // iOS: uygulama açıkken (foreground) de banner/sound göster.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Yerel bildirim eklentisi (foreground gösterimi için)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ));

    // Android 8+ için bildirim kanalını oluştur (arka plan FCM bildirimleri için)
    const channel = AndroidNotificationChannel(
      'events_channel',
      'Etkinlik Bildirimleri',
      description: 'Davet ve etkinlik bildirimleri',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // iOS: FCM token'ı almadan önce APNs token'ının hazır olmasını bekle.
    // APNs kaydı tamamlanmadan getToken() null dönebilir; kısa bir retry ile
    // (maks ~10 sn) APNs token'ını bekleriz. Aksi halde cron'a yazılacak
    // geçerli token oluşmaz ve iOS'a push gelmez.
    if (Platform.isIOS) {
      for (var i = 0; i < 10; i++) {
        final apns = await _fcm.getAPNSToken();
        if (apns != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // Token al ve kullanıcıya kaydet
    final token = await _fcm.getToken();
    if (token != null) {
      await _userService.addFcmToken(uid, token);
    }
    // Önceki abonelikleri (varsa) iptal et — çift dinleyiciyi önler.
    await dispose();
    _tokenRefreshSub =
        _fcm.onTokenRefresh.listen((t) => _userService.addFcmToken(uid, t));

    // Uygulama açıkken gelen bildirimi yerel olarak göster
    _onMessageSub = FirebaseMessaging.onMessage.listen(_showForeground);
  }

  /// Abonelikleri iptal eder (çift foreground bildirimi/token sızıntısını önler).
  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    _tokenRefreshSub = null;
    _onMessageSub = null;
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'events_channel',
        'Etkinlik Bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      details,
    );
  }

  /// Yerel (istemci-taraflı) no-show bildirimi gösterimi.
  /// Cron erişilemediğinde host kendi cihazında bilgi alır.
  Future<void> showLocal(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'events_channel',
        'Etkinlik Bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    // 32-bit int aralığında benzersiz ID (millisecond [0-999] çakışmasını önler).
    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
    await _local.show(id, title, body, details);
  }
}

/// Arka planda (terminated/background) gelen mesaj için top-level handler.
/// main.dart içinde FirebaseMessaging.onBackgroundMessage ile kaydedilir.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda işlem gerekmiyorsa boş kalabilir; sistem bildirimi gösterir.
}
