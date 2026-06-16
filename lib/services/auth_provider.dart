import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Oturum ve profil durumunu tutar.
class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _users = UserService();

  StreamSubscription<User?>? _authSub;
  User? _firebaseUser;
  AppUser? _profile;
  bool _loading = true;

  User? get firebaseUser => _firebaseUser;
  AppUser? get profile => _profile;
  bool get loading => _loading;
  bool get isLoggedIn => _firebaseUser != null;

  /// Profil var ve onboarding (username + interests) tamamlandı mı?
  bool get onboardingDone =>
      _profile != null &&
      _profile!.username.isNotEmpty &&
      _profile!.interests.isNotEmpty;

  AuthProvider() {
    _authSub = _auth.authState.listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _profile = await _users.getUser(user.uid);
    } else {
      _profile = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> reloadProfile() async {
    if (_firebaseUser == null) return;
    _profile = await _users.getUser(_firebaseUser!.uid);
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();
}
