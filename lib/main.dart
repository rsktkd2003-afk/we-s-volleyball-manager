import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

          return _AuthenticatedHome(user: authSnapshot.data!);
        },
      ),
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome({required this.user});

  final User user;

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  late Future<void> ensureUserDocument;

  @override
  void initState() {
    super.initState();
    ensureUserDocument = AccountService.ensureUserDocument(widget.user);
  }

  @override
  void didUpdateWidget(covariant _AuthenticatedHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      ensureUserDocument = AccountService.ensureUserDocument(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: ensureUserDocument,
      builder: (context, ensureSnapshot) {
        if (ensureSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (ensureSnapshot.hasError) {
          return _UserLoadError(error: ensureSnapshot.error);
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.usersRef.doc(widget.user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (userSnapshot.hasError) {
              return _UserLoadError(error: userSnapshot.error);
            }

            final userData = userSnapshot.data?.data();
            if (userData == null) {
              return const _UserLoadError(error: 'ユーザー情報が見つかりません');
            }

            final role = userData['role'] as String? ?? 'member';
            final playerId = userData['playerId'] as String?;

            if (role == 'member' &&
                (playerId == null || playerId.isEmpty)) {
              return const PlayerLinkScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _UserLoadError extends StatelessWidget {
  const _UserLoadError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'ユーザー情報の読み込みに失敗しました: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
