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

  Future<void> init(String uid) async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

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

    // Token al ve kullanıcıya kaydet
    final token = await _fcm.getToken();
    if (token != null) {
      await _userService.addFcmToken(uid, token);
    }
    _fcm.onTokenRefresh.listen((t) => _userService.addFcmToken(uid, t));

    // Uygulama açıkken gelen bildirimi yerel olarak göster
    FirebaseMessaging.onMessage.listen(_showForeground);
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
    await _local.show(DateTime.now().millisecond, title, body, details);
  }
}

/// Arka planda (terminated/background) gelen mesaj için top-level handler.
/// main.dart içinde FirebaseMessaging.onBackgroundMessage ile kaydedilir.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda işlem gerekmiyorsa boş kalabilir; sistem bildirimi gösterir.
}
