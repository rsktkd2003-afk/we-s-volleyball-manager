import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/firestore_collections.dart';

/// NotificationServiceが「現在ログイン中のuid」を参照するための最小インターフェース。
/// firebase_authのUser/FirebaseAuthは直接フェイクしづらいため、
/// 実際に必要な参照(uidのみ)に絞って抽象化している。
abstract class AuthUidProvider {
  String? get currentUid;
}

class FirebaseAuthUidProvider implements AuthUidProvider {
  FirebaseAuthUidProvider(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;
}

/// NotificationServiceが利用するFirebase Messaging操作の最小インターフェース。
abstract class MessagingGateway {
  Future<AuthorizationStatus> requestPermission();
  Future<AuthorizationStatus> getAuthorizationStatus();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
}

class FirebaseMessagingGateway implements MessagingGateway {
  FirebaseMessagingGateway(this._messaging, {required this.webVapidKey});

  final FirebaseMessaging _messaging;
  final String webVapidKey;

  @override
  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus;
  }

  @override
  Future<AuthorizationStatus> getAuthorizationStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  @override
  Future<String?> getToken() {
    if (kIsWeb) {
      return _messaging.getToken(
        vapidKey: webVapidKey.isEmpty ? null : webVapidKey,
      );
    }

    return _messaging.getToken();
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

/// users/{uid}/fcmTokens への書き込み・削除の最小インターフェース。
abstract class TokenStore {
  Future<void> save(String uid, String token, {required String platform});
  Future<void> delete(String uid, String token);
}

class FirestoreTokenStore implements TokenStore {
  FirestoreTokenStore(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> save(String uid, String token, {required String platform}) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.fcmTokens)
        .doc(token)
        .set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid, String token) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.fcmTokens)
        .doc(token)
        .delete();
  }
}

/// 端末ごとの通知設定(SharedPreferencesAsync)の最小インターフェース。
abstract class PreferenceStore {
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
}

class SharedPreferenceStore implements PreferenceStore {
  SharedPreferenceStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool?> getBool(String key) => _preferences.getBool(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);
}
