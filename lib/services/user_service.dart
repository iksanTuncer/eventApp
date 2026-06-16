import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// users/{uid} koleksiyonu işlemleri.
class UserService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> createUser(AppUser user) async {
    await _col.doc(user.uid).set(user.toMap());
  }

  Future<void> updateProfile(
    String uid, {
    String? username,
    String? photoBase64,
    List<String>? interests,
  }) async {
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (photoBase64 != null) data['photoBase64'] = photoBase64;
    if (interests != null) data['interests'] = interests;
    if (data.isEmpty) return;
    await _col.doc(uid).update(data);
  }

  /// FCM token'ları herkese açık profil dokümanında DEĞİL, sadece sahibinin
  /// (ve Admin SDK ile cron worker'ın) okuyabildiği özel alt-dokümanda tutulur.
  DocumentReference<Map<String, dynamic>> _pushDoc(String uid) =>
      _col.doc(uid).collection('private').doc('push');

  /// FCM token ekle (çoklu cihaz). arrayUnion ile tekrar yazımı önler.
  Future<void> addFcmToken(String uid, String token) async {
    await _pushDoc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> removeFcmToken(String uid, String token) async {
    await _pushDoc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  /// Verilen uid'ler için kullanıcı haritası döndürür (uid -> AppUser).
  /// Firestore whereIn 10'lu sınırı nedeniyle parçalara bölünerek okunur.
  Future<Map<String, AppUser>> getUsersByUids(List<String> uids) async {
    final result = <String, AppUser>{};
    final unique = uids.toSet().toList();
    for (var i = 0; i < unique.length; i += 10) {
      final end = (i + 10) < unique.length ? i + 10 : unique.length;
      final chunk = unique.sublist(i, end);
      final snap =
          await _col.where(FieldPath.documentId, whereIn: chunk).get();
      for (final d in snap.docs) {
        result[d.id] = AppUser.fromMap(d.id, d.data());
      }
    }
    return result;
  }

  /// Davetli seçimi için tüm kullanıcıları getirir (kendisi hariç).
  /// Not: Hobi ölçeği için yeterli. Büyürse arama/sayfalama eklenmeli.
  Future<List<AppUser>> listOtherUsers(String myUid) async {
    final snap = await _col.limit(200).get();
    return snap.docs
        .where((d) => d.id != myUid)
        .map((d) => AppUser.fromMap(d.id, d.data()))
        .toList();
  }
}
