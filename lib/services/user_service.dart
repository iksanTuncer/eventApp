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

  /// FCM token ekle (çoklu cihaz). arrayUnion ile tekrar yazımı önler.
  Future<void> addFcmToken(String uid, String token) async {
    await _col.doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  Future<void> removeFcmToken(String uid, String token) async {
    await _col.doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
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
