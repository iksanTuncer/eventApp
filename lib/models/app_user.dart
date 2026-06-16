import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String? photoBase64;
  final List<String> interests;
  final List<String> fcmTokens;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.photoBase64,
    this.interests = const [],
    this.fcmTokens = const [],
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    return AppUser(
      uid: uid,
      email: m['email'] ?? '',
      username: m['username'] ?? '',
      photoBase64: m['photoBase64'],
      interests: List<String>.from(m['interests'] ?? const []),
      fcmTokens: List<String>.from(m['fcmTokens'] ?? const []),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'username': username,
        if (photoBase64 != null) 'photoBase64': photoBase64,
        'interests': interests,
        'fcmTokens': fcmTokens,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  AppUser copyWith({
    String? username,
    String? photoBase64,
    List<String>? interests,
    List<String>? fcmTokens,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      username: username ?? this.username,
      photoBase64: photoBase64 ?? this.photoBase64,
      interests: interests ?? this.interests,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt,
    );
  }
}
