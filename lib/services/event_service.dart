import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_event.dart';
import '../models/missed_event.dart';
import '../utils/constants.dart';

/// events/{eventId} ve alt-koleksiyon rsvps işlemleri.
class EventService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('events');

  /// Yeni etkinlik oluşturur ve her davetli için pending RSVP açar.
  Future<String> createEvent(AppEvent event) async {
    final ref = _col.doc();
    // createdAt için serverTimestamp toMap içinde ayarlı. eventId'yi ekle.
    final data = event.toMap()..['eventId'] = ref.id;
    await ref.set(data);

    // Davetliler için başlangıç pending RSVP kayıtları (batch).
    if (event.inviteeUids.isNotEmpty) {
      final batch = _db.batch();
      for (final uid in event.inviteeUids) {
        final rsvpRef = ref.collection('rsvps').doc(uid);
        batch.set(rsvpRef, {
          'uid': uid,
          'username': '', // RSVP yanıtında güncellenecek
          'status': RsvpStatus.pending,
        });
      }
      await batch.commit();
    }
    return ref.id;
  }

  /// Davet edildiğim aktif etkinlikler (bitiş zamanı gelmemiş).
  Stream<List<AppEvent>> invitedEvents(String uid) {
    return _col
        .where('inviteeUids', arrayContains: uid)
        .where('endAt', isGreaterThan: Timestamp.now())
        .orderBy('endAt')
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppEvent.fromMap(d.id, d.data())).toList());
  }

  /// Düzenlediğim aktif etkinlikler.
  Stream<List<AppEvent>> hostedEvents(String uid) {
    return _col
        .where('hostUid', isEqualTo: uid)
        .where('endAt', isGreaterThan: Timestamp.now())
        .orderBy('endAt')
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppEvent.fromMap(d.id, d.data())).toList());
  }

  Future<AppEvent?> getEvent(String eventId) async {
    final doc = await _col.doc(eventId).get();
    if (!doc.exists) return null;
    return AppEvent.fromMap(eventId, doc.data()!);
  }

  /// RSVP yanıtı kaydet/güncelle.
  Future<void> respond(
      String eventId, String uid, String username, String status) async {
    await _col.doc(eventId).collection('rsvps').doc(uid).set({
      'uid': uid,
      'username': username,
      'status': status,
      'respondedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Belirli kullanıcının bu etkinlikteki RSVP durumu.
  Future<String?> myRsvpStatus(String eventId, String uid) async {
    final doc =
        await _col.doc(eventId).collection('rsvps').doc(uid).get();
    return doc.data()?['status'] as String?;
  }

  /// Host için: tüm RSVP'leri canlı dinle (detay ekranı).
  Stream<List<Rsvp>> rsvpStream(String eventId) {
    return _col.doc(eventId).collection('rsvps').snapshots().map(
        (s) => s.docs.map((d) => Rsvp.fromMap(d.id, d.data())).toList());
  }

  /// Etkinliği ve alt-koleksiyonunu (rsvps) tamamen sil.
  Future<void> deleteEventDeep(String eventId) async {
    final rsvps = await _col.doc(eventId).collection('rsvps').get();
    final batch = _db.batch();
    for (final d in rsvps.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_col.doc(eventId));
    await batch.commit();
  }

  /// Kaçırdıklarım: cron worker'ın yazdığı, süresi geçip silinen ama
  /// kullanıcının kaçırdığı etkinliklerin görsel + mesaj kayıtları.
  Stream<List<MissedEvent>> missedEvents(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('missed')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => MissedEvent.fromMap(d.id, d.data())).toList());
  }

  /// Kaçırılan etkinlik kaydını kullanıcı listeden kaldırır.
  Future<void> dismissMissed(String uid, String eventId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('missed')
        .doc(eventId)
        .delete();
  }
}
