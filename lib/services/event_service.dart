import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_event.dart';
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

  /// İstemci-taraflı temizlik için: süresi geçmiş, henüz işlenmemiş etkinlikler.
  /// Sadece bu kullanıcının HOST olduğu etkinlikleri döndürür (kurallar gereği).
  Future<List<AppEvent>> expiredHostedUnprocessed(String uid) async {
    final snap = await _col
        .where('hostUid', isEqualTo: uid)
        .where('endAt', isLessThan: Timestamp.now())
        .limit(20)
        .get();
    return snap.docs
        .map((d) => AppEvent.fromMap(d.id, d.data()))
        .where((e) => !e.processed)
        .toList();
  }

  /// İşlendi olarak işaretle (çift bildirimi önler).
  Future<void> markProcessed(String eventId) async {
    await _col.doc(eventId).update({'processed': true, 'status': 'ended'});
  }

  /// Bir etkinlikte gelmeyen (no/pending) davetlilerin uid listesini döndürür.
  Future<List<String>> noShowUids(String eventId) async {
    final rsvps = await _col.doc(eventId).collection('rsvps').get();
    return rsvps.docs
        .where((d) {
          final st = d.data()['status'];
          return st == RsvpStatus.no || st == RsvpStatus.pending;
        })
        .map((d) => d.id)
        .toList();
  }
}
