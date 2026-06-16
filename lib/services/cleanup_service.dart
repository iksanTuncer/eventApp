import 'event_service.dart';
import 'notification_service.dart';

/// İstemci-taraflı temizlik. Uygulama açıldığında çalışır.
/// Kullanıcının HOST olduğu, süresi geçmiş, işlenmemiş etkinlikleri:
///  1. Gelmeyenler için yerel bilgi bildirimi gösterir (host'a),
///  2. (No-show FCM'i asıl cron worker server-side gönderir),
///  3. Etkinliği ve rsvps alt-koleksiyonunu siler.
///
/// Cron worker (GitHub Actions) zaten arka planda aynı işi tüm kullanıcılar
/// için yapar; bu istemci tarafı, uygulama hemen açıldığında anında temizlik
/// ve host'a geri bildirim sağlar. `processed`/silme idempotent olduğu için
/// çift çalışsa da sorun olmaz.
class CleanupService {
  final _events = EventService();
  final _notif = NotificationService();

  Future<void> runForHost(String uid) async {
    try {
      final expired = await _events.expiredHostedUnprocessed(uid);
      for (final e in expired) {
        final noShow = await _events.noShowUids(e.eventId);

        // Host'a yerel özet bildirimi
        if (noShow.isNotEmpty) {
          await _notif.showLocal(
            'Etkinlik bitti: ${e.title}',
            '${noShow.length} kişi katılmadı. Bildirimleri gönderildi.',
          );
        }

        // İşlendi işaretle (cron ile çift göndermeyi önler), sonra sil.
        await _events.markProcessed(e.eventId);
        await _events.deleteEventDeep(e.eventId);
      }
    } catch (_) {
      // Sessizce geç; bir sonraki açılışta veya cron ile tekrar denenir.
    }
  }
}
