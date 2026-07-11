import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utils/firestore_collections.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');

  static Future<void> initialize() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await _getTokenSafely();
      if (token == null || token.isEmpty) return;

      await _saveToken(user.uid, token);

      _messaging.onTokenRefresh.listen((newToken) async {
        final currentUser = _auth.currentUser;
        if (currentUser == null || newToken.isEmpty) return;
        await _saveToken(currentUser.uid, newToken);
      });
    } catch (_) {
      // 通知初期化に失敗してもアプリ本体は止めない
    }
  }

  static Future<String?> _getTokenSafely() async {
    try {
      if (kIsWeb) {
        return await _messaging.getToken(
          vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey,
        );
      }

      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.fcmTokens)
        .doc(token)
        .set({
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}