import 'package:cloud_firestore/cloud_firestore.dart';

/// Bildirim kuyruğu: İstemci doğrudan başka cihaza FCM gönderemez (sunucu
/// anahtarı güvenliği). Bunun yerine 'notifications' koleksiyonuna bir görev
/// yazar; GitHub Actions cron worker (scripts/cron_worker.js) bu görevleri
/// okur, hedef kullanıcıların fcmTokens'larına FCM gönderir ve görevi siler.
///
/// Bu, hem ücretsiz hem güvenli yöntemdir.
class NotificationQueueService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  /// Davet bildirimi kuyruğa ekle.
  Future<void> enqueueInvite({
    required List<String> targetUids,
    required String hostUsername,
    required String eventTitle,
    required String eventId,
  }) async {
    await _col.add({
      'kind': 'invite',
      'targetUids': targetUids,
      'title': 'Yeni etkinlik daveti',
      'body': '$hostUsername seni "$eventTitle" etkinliğine davet etti',
      'eventId': eventId,
      'createdAt': FieldValue.serverTimestamp(),
      'sent': false,
    });
  }
}
