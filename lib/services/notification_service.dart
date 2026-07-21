import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_status.dart';
import '../utils/async_serial_queue.dart';
import '../utils/firestore_collections.dart';
import '../utils/notification_session_guard.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static const String _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static const String _notificationsEnabledKey = 'notifications_enabled';

  static final AsyncSerialQueue _tokenMutationQueue = AsyncSerialQueue();
  static final NotificationSessionGuard _sessionGuard =
      NotificationSessionGuard();

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _registeredToken;

  static bool get _isWebConfigurationMissing =>
      kIsWeb && _webVapidKey.isEmpty;

  static Future<void> initialize() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final session = _sessionGuard.capture(user.uid);

      final preferenceEnabled = await _isPreferenceEnabled();
      if (!preferenceEnabled) return;

      if (_isWebConfigurationMissing) {
        if (_isSessionCurrent(session)) {
          await _setPreferenceEnabled(false);
        }
        return;
      }

      final settings = await _messaging.requestPermission();
      if (!_isSessionCurrent(session)) return;

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await _setPreferenceEnabled(false);
        return;
      }

      await _registerCurrentToken(session);
      if (_isSessionCurrent(session)) {
        await _startTokenRefreshListener();
      }
    } catch (_) {
      // 通知初期化に失敗してもアプリ本体は止めない
    }
  }

  static Future<AppNotificationStatus> loadStatus() async {
    var preferenceEnabled = await _isPreferenceEnabled();

    if (_isWebConfigurationMissing) {
      if (preferenceEnabled) {
        await _setPreferenceEnabled(false);
        preferenceEnabled = false;
      }

      return const AppNotificationStatus(
        preferenceEnabled: false,
        permission: AppNotificationPermission.unavailable,
        tokenAvailable: false,
      );
    }

    try {
      final settings = await _messaging.getNotificationSettings();
      final permission = _mapPermission(settings.authorizationStatus);
      final permissionGranted =
          permission == AppNotificationPermission.authorized ||
          permission == AppNotificationPermission.provisional;
      final token = preferenceEnabled && permissionGranted
          ? await _getTokenSafely()
          : null;
      if (token != null && token.isNotEmpty) {
        _registeredToken = token;
      }

      return AppNotificationStatus(
        preferenceEnabled: preferenceEnabled,
        permission: permission,
        tokenAvailable: token != null && token.isNotEmpty,
      );
    } catch (_) {
      if (preferenceEnabled) {
        await _setPreferenceEnabled(false);
      }

      return const AppNotificationStatus(
        preferenceEnabled: false,
        permission: AppNotificationPermission.unavailable,
        tokenAvailable: false,
      );
    }
  }

  static Future<AppNotificationStatus> setEnabled(bool enabled) async {
    if (!enabled) {
      await _disableForCurrentDevice();
      return loadStatus();
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('ログイン情報が見つかりません');
    }
    final session = _sessionGuard.capture(user.uid);

    if (_isWebConfigurationMissing) {
      await _setPreferenceEnabled(false);
      return loadStatus();
    }

    await _setPreferenceEnabled(true);

    try {
      final settings = await _messaging.requestPermission();
      if (!_isSessionCurrent(session)) return loadStatus();

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await _setPreferenceEnabled(false);
        return loadStatus();
      }

      await _registerCurrentToken(session);
      if (_isSessionCurrent(session)) {
        await _startTokenRefreshListener();
      }
      return loadStatus();
    } catch (_) {
      if (_isSessionCurrent(session)) {
        await _setPreferenceEnabled(false);
      }
      rethrow;
    }
  }

  static Future<void> detachCurrentUser() async {
    _sessionGuard.invalidate();

    try {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      final user = _auth.currentUser;
      final token = await _getExistingTokenSafely();
      if (user == null || token == null || token.isEmpty) return;

      await _deleteStoredToken(user.uid, token);
    } catch (_) {
      // 通知の後処理に失敗してもログアウトを妨げない
    } finally {
      _registeredToken = null;
    }
  }

  static Future<TestNotificationResult> sendTestNotification() async {
    try {
      final response = await _functions
          .httpsCallable('sendTestNotification')
          .call();
      final data = Map<String, dynamic>.from(response.data as Map);

      return TestNotificationResult(
        successCount: data['successCount'] as int? ?? 0,
        failureCount: data['failureCount'] as int? ?? 0,
      );
    } on FirebaseFunctionsException catch (error) {
      throw TestNotificationException(_testNotificationErrorMessage(error));
    }
  }

  static Future<void> _disableForCurrentDevice() async {
    _sessionGuard.invalidate();

    final token = await _getExistingTokenSafely();
    await _setPreferenceEnabled(false);
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final user = _auth.currentUser;

    if (user != null && token != null && token.isNotEmpty) {
      try {
        await _deleteStoredToken(user.uid, token);
      } catch (_) {
        // トークン無効化を優先し、古いFirestore記録は送信失敗に委ねる
      }
    }

    try {
      await _messaging.deleteToken();
    } catch (_) {
      // 未対応環境でも端末設定の保存は完了させる
    } finally {
      _registeredToken = null;
    }
  }

  static Future<void> _registerCurrentToken(
    NotificationSession session,
  ) async {
    final token = await _getTokenSafely();
    if (token == null || token.isEmpty) return;
    if (!_isSessionCurrent(session)) return;

    await _saveToken(session, token);
    if (_isSessionCurrent(session)) {
      _registeredToken = token;
    }
  }

  static Future<void> _startTokenRefreshListener() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) async {
        final currentUser = _auth.currentUser;
        if (currentUser == null || newToken.isEmpty) return;
        final session = _sessionGuard.capture(currentUser.uid);

        try {
          if (await _isPreferenceEnabled() && _isSessionCurrent(session)) {
            final previousToken = _registeredToken;
            if (previousToken != null && previousToken != newToken) {
              try {
                await _deleteStoredToken(session.uid, previousToken);
              } catch (_) {
                // 新しいトークンの保存を優先する
              }
            }

            await _saveToken(session, newToken);
            if (_isSessionCurrent(session)) {
              _registeredToken = newToken;
            }
          }
        } catch (_) {
          // 更新トークンの保存失敗でアプリを止めない
        }
      },
    );
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

  static Future<String?> _getExistingTokenSafely() async {
    if (_registeredToken != null && _registeredToken!.isNotEmpty) {
      return _registeredToken;
    }

    try {
      final settings = await _messaging.getNotificationSettings();
      final status = settings.authorizationStatus;
      final permissionGranted =
          status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      if (!permissionGranted) return null;

      return _getTokenSafely();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveToken(
    NotificationSession session,
    String token,
  ) {
    return _tokenMutationQueue.add(() async {
      if (!_isSessionCurrent(session)) return;

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(session.uid)
          .collection(FirestoreCollections.fcmTokens)
          .doc(token)
          .set({
        'token': token,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<void> _deleteStoredToken(String uid, String token) {
    return _tokenMutationQueue.add(() {
      return _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .collection(FirestoreCollections.fcmTokens)
          .doc(token)
          .delete();
    });
  }

  static Future<bool> _isPreferenceEnabled() async {
    return await _preferences.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> _setPreferenceEnabled(bool enabled) {
    return _preferences.setBool(_notificationsEnabledKey, enabled);
  }

  static bool _isSessionCurrent(NotificationSession session) {
    return _sessionGuard.isCurrent(session, _auth.currentUser?.uid);
  }

  static AppNotificationPermission _mapPermission(
    AuthorizationStatus status,
  ) {
    switch (status) {
      case AuthorizationStatus.notDetermined:
        return AppNotificationPermission.notDetermined;
      case AuthorizationStatus.denied:
        return AppNotificationPermission.denied;
      case AuthorizationStatus.authorized:
        return AppNotificationPermission.authorized;
      case AuthorizationStatus.provisional:
        return AppNotificationPermission.provisional;
    }
  }

  static String _testNotificationErrorMessage(
    FirebaseFunctionsException error,
  ) {
    switch (error.code) {
      case 'unauthenticated':
        return '再度ログインしてください。';
      case 'failed-precondition':
        return 'この端末の通知トークンが登録されていません。';
      case 'resource-exhausted':
        return '30秒待ってから再度お試しください。';
      default:
        return error.message ?? 'テスト通知の送信に失敗しました。';
    }
  }
}

class TestNotificationResult {
  const TestNotificationResult({
    required this.successCount,
    required this.failureCount,
  });

  final int successCount;
  final int failureCount;
}

class TestNotificationException implements Exception {
  const TestNotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
