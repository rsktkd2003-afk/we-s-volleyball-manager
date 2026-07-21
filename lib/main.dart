import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/player_link_screen.dart';
import 'services/account_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      NotificationService.initialize();
    }
  });

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _resolveHomeAfterLogin(User user) async {
    await AccountService.ensureUserDocument(user);
    final userData = await FirestoreService.loadCurrentUserData();

    if (userData == null) {
      return const LoginScreen();
    }

    final role = userData['role'] as String? ?? 'member';
    final playerId = userData['playerId'] as String?;

    if (role == 'member' && (playerId == null || playerId.isEmpty)) {
      return const PlayerLinkScreen();
    }

    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "We's Volleyball Manager",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!authSnapshot.hasData) {
            return const LoginScreen();
          }

          return FutureBuilder<Widget>(
            future: _resolveHomeAfterLogin(authSnapshot.data!),
            builder: (context, homeSnapshot) {
              if (homeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (homeSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('ユーザー情報の読み込みに失敗しました: ${homeSnapshot.error}'),
                  ),
                );
              }

              return homeSnapshot.data ?? const LoginScreen();
            },
          );
        },
      ),
    );
  }
}
