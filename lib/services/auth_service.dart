import 'package:firebase_auth/firebase_auth.dart';

/// Email + password ile Firebase Authentication. Ücretsiz Spark planında çalışır.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Hassas işlemler (hesap silme) öncesi yeniden kimlik doğrulama.
  /// Firebase, hesap silmeyi yalnızca yakın zamanda giriş yapılmışsa kabul eder.
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'Oturum bulunamadı.');
    }
    final cred =
        EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  /// Firebase Auth hesabını siler. Çağrıdan önce reauthenticate gerekir.
  Future<void> deleteAccount() => _auth.currentUser!.delete();

  /// FirebaseAuthException kodlarını Türkçe mesaja çevirir.
  static String messageFor(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Geçersiz e-posta.';
        case 'email-already-in-use':
          return 'Bu e-posta zaten kayıtlı.';
        case 'weak-password':
          return 'Şifre çok zayıf (en az 6 karakter).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-posta veya şifre hatalı.';
        case 'too-many-requests':
          return 'Çok fazla deneme. Biraz bekle.';
        case 'requires-recent-login':
          return 'Güvenlik için lütfen çıkış yapıp tekrar giriş yap, sonra dene.';
        default:
          return 'Giriş hatası: ${e.code}';
      }
    }
    return 'Bilinmeyen hata.';
  }
}
