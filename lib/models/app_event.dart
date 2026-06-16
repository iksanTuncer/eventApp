import 'package:cloud_firestore/cloud_firestore.dart';

class AppEvent {
  final String eventId;
  final String hostUid;
  final String hostUsername;
  final String type;
  final String title;
  final String imageBase64;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String locationMode; // 'map' | 'text'
  final String? locationText;
  final double? lat;
  final double? lng;
  final List<String> inviteeUids;
  final String? noShowImageBase64;
  final String? noShowMessage;
  final String status; // 'active' | 'ended'
  final bool processed;
  final DateTime? createdAt;

  AppEvent({
    required this.eventId,
    required this.hostUid,
    required this.hostUsername,
    required this.type,
    required this.title,
    required this.imageBase64,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.locationMode,
    this.locationText,
    this.lat,
    this.lng,
    this.inviteeUids = const [],
    this.noShowImageBase64,
    this.noShowMessage,
    this.status = 'active',
    this.processed = false,
    this.createdAt,
  });

  factory AppEvent.fromMap(String id, Map<String, dynamic> m) {
    return AppEvent(
      eventId: id,
      hostUid: m['hostUid'] ?? '',
      hostUsername: m['hostUsername'] ?? '',
      type: m['type'] ?? 'other',
      title: m['title'] ?? '',
      imageBase64: m['imageBase64'] ?? '',
      description: m['description'],
      startAt: (m['startAt'] as Timestamp).toDate(),
      endAt: (m['endAt'] as Timestamp).toDate(),
      locationMode: m['locationMode'] ?? 'text',
      locationText: m['locationText'],
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      inviteeUids: List<String>.from(m['inviteeUids'] ?? const []),
      noShowImageBase64: m['noShowImageBase64'],
      noShowMessage: m['noShowMessage'],
      status: m['status'] ?? 'active',
      processed: m['processed'] ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'hostUid': hostUid,
        'hostUsername': hostUsername,
        'type': type,
        'title': title,
        'imageBase64': imageBase64,
        if (description != null) 'description': description,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'locationMode': locationMode,
        if (locationText != null) 'locationText': locationText,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'inviteeUids': inviteeUids,
        if (noShowImageBase64 != null) 'noShowImageBase64': noShowImageBase64,
        if (noShowMessage != null) 'noShowMessage': noShowMessage,
        'status': status,
        'processed': processed,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  bool get isEnded => DateTime.now().isAfter(endAt);
}

class Rsvp {
  final String uid;
  final String username;
  final String status; // pending | yes | no
  final DateTime? respondedAt;

  Rsvp({
    required this.uid,
    required this.username,
    required this.status,
    this.respondedAt,
  });

  factory Rsvp.fromMap(String uid, Map<String, dynamic> m) => Rsvp(
        uid: uid,
        username: m['username'] ?? '',
        status: m['status'] ?? 'pending',
        respondedAt: (m['respondedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'status': status,
        'respondedAt': respondedAt != null
            ? Timestamp.fromDate(respondedAt!)
            : FieldValue.serverTimestamp(),
      };
}
