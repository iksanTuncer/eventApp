import 'package:cloud_firestore/cloud_firestore.dart';

/// users/{uid}/missed/{eventId} — Süresi geçip silinen ama kullanıcının
/// kaçırdığı (no/pending) etkinliğin görseli + no-show mesajı.
/// Cron worker (Admin SDK) yazar; istemci sadece okur/siler.
class MissedEvent {
  final String eventId;
  final String title;
  final String type;
  final String hostUsername;
  final String imageBase64;
  final String noShowMessage;
  final DateTime? endAt;
  final DateTime? createdAt;

  MissedEvent({
    required this.eventId,
    required this.title,
    required this.type,
    required this.hostUsername,
    required this.imageBase64,
    required this.noShowMessage,
    this.endAt,
    this.createdAt,
  });

  factory MissedEvent.fromMap(String id, Map<String, dynamic> m) {
    return MissedEvent(
      eventId: id,
      title: m['title'] ?? '',
      type: m['type'] ?? 'other',
      hostUsername: m['hostUsername'] ?? '',
      imageBase64: m['imageBase64'] ?? '',
      noShowMessage: m['noShowMessage'] ?? '',
      endAt: (m['endAt'] as Timestamp?)?.toDate(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
