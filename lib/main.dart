import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/strings.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/profile_screen.dart';
import 'screens/onboarding/interests_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null); // Türkçe tarih biçimi
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Arka plan bildirim handler'ı (FCM)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const EventApp(),
    ),
  );
}

class EventApp extends StatelessWidget {
  const EventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _Root(),
    );
  }
}

/// Oturum ve onboarding durumuna göre doğru ekrana yönlendirir.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // Giriş yapılmış ama profil yok → onboarding profil
    if (auth.profile == null || auth.profile!.username.isEmpty) {
      return const ProfileScreen();
    }
    // Profil var ama ilgi alanı seçilmemiş → onboarding ilgi
    if (auth.profile!.interests.isEmpty) {
      return const InterestsScreen();
    }
    return const HomeScreen();
  }
}
