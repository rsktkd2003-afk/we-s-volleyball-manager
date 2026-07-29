import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_status.dart';
import '../utils/async_serial_queue.dart';
import '../utils/notification_session_guard.dart';
import 'notification_dependencies.dart';

class NotificationService {
  NotificationService._();

  static const String _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static const String _notificationsEnabledKey = 'notifications_enabled';

  static AuthUidProvider _authUidProvider =
      FirebaseAuthUidProvider(FirebaseAuth.instance);
  static MessagingGateway _messagingGateway = FirebaseMessagingGateway(
    FirebaseMessaging.instance,
    webVapidKey: _webVapidKey,
  );
  static TokenStore _tokenStore =
      FirestoreTokenStore(FirebaseFirestore.instance);
  static PreferenceStore _preferenceStore =
      SharedPreferenceStore(SharedPreferencesAsync());

  static AsyncSerialQueue _tokenMutationQueue = AsyncSerialQueue();
  static NotificationSessionGuard _sessionGuard = NotificationSessionGuard();

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _registeredToken;

  static bool get _isWebConfigurationMissing =>
      kIsWeb && _webVapidKey.isEmpty;

  /// テスト専用: Firebase依存部分を差し替える。
  @visibleForTesting
  static void configureForTesting({
    AuthUidProvider? authUidProvider,
    MessagingGateway? messagingGateway,
    TokenStore? tokenStore,
    PreferenceStore? preferenceStore,
  }) {
    if (authUidProvider != null) _authUidProvider = authUidProvider;
    if (messagingGateway != null) _messagingGateway = messagingGateway;
    if (tokenStore != null) _tokenStore = tokenStore;
    if (preferenceStore != null) _preferenceStore = preferenceStore;
  }

  /// テスト専用: セッション世代・キュー・購読などの内部状態をリセットする。
  ///
  /// 依存関係(AuthUidProvider等)は本番のFirebaseインスタンスへ差し替えない
  /// (テスト環境ではFirebase.initializeApp()が呼ばれておらず失敗するため)。
  /// 次のテストのsetUpでconfigureForTestingにより上書きされる想定。
  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _registeredToken = null;
    _sessionGuard = NotificationSessionGuard();
    _tokenMutationQueue = AsyncSerialQueue();
  }

  static Future<void> initialize() async {
    try {
      final uid = _authUidProvider.currentUid;
      if (uid == null) return;
      final session = _sessionGuard.capture(uid);

      final preferenceEnabled = await _isPreferenceEnabled();
      if (!preferenceEnabled) return;

      if (_isWebConfigurationMissing) {
        if (_isSessionCurrent(session)) {
          await _setPreferenceEnabled(false);
        }
        return;
      }

      final status = await _messagingGateway.requestPermission();
      if (!_isSessionCurrent(session)) return;

      if (status == AuthorizationStatus.denied) {
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
        permission: AppNotificationPermission.webVapidNotConfigured,
        tokenAvailable: false,
      );
    }

    try {
      final authorizationStatus =
          await _messagingGateway.getAuthorizationStatus();
      final permission = _mapPermission(authorizationStatus);
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

  /// 通知オン/オフを切り替える。
  ///
  /// ONにする場合は「権限取得→権限確認→トークン取得→Firestore登録」の
  /// 全ステップが成功した場合のみ端末設定をtrueのまま残す。
  /// いずれかのステップが失敗した場合(例外・拒否・トークン取得失敗・
  /// Firestore書き込み失敗)は必ずfalseへロールバックする。
  ///
  /// 処理中に別セッション(ログアウト/別ユーザーへの切り替え)が始まった
  /// 場合は、古いセッション側からは設定を書き換えずに終了する
  /// (新しいセッション自身のinitialize/setEnabledが最終状態を決めるため、
  /// 古いセッションが割り込んでpreferenceを上書きすると、新しいセッションが
  /// 既に完了させた正しい状態を壊してしまう恐れがある)。
  static Future<AppNotificationStatus> setEnabled(bool enabled) async {
    if (!enabled) {
      await _disableForCurrentDevice();
      return loadStatus();
    }

    final uid = _authUidProvider.currentUid;
    if (uid == null) {
      throw StateError('ログイン情報が見つかりません');
    }
    final session = _sessionGuard.capture(uid);

    if (_isWebConfigurationMissing) {
      await _setPreferenceEnabled(false);
      return loadStatus();
    }

    await _setPreferenceEnabled(true);

    try {
      final status = await _messagingGateway.requestPermission();
      if (!_isSessionCurrent(session)) return loadStatus();

      if (status == AuthorizationStatus.denied) {
        await _setPreferenceEnabled(false);
        return loadStatus();
      }

      final registered = await _registerCurrentToken(session);
      if (!_isSessionCurrent(session)) return loadStatus();

      if (!registered) {
        await _setPreferenceEnabled(false);
        return loadStatus();
      }

      await _startTokenRefreshListener();
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

      final uid = _authUidProvider.currentUid;
      final token = await _getExistingTokenSafely();
      if (uid == null || token == null || token.isEmpty) return;

      await _tokenStore.delete(uid, token);
    } catch (_) {
      // 通知の後処理に失敗してもログアウトを妨げない
    } finally {
      _registeredToken = null;
    }
  }

  static Future<void> _disableForCurrentDevice() async {
    _sessionGuard.invalidate();

    final token = await _getExistingTokenSafely();
    await _setPreferenceEnabled(false);
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final uid = _authUidProvider.currentUid;

    if (uid != null && token != null && token.isNotEmpty) {
      try {
        await _tokenStore.delete(uid, token);
      } catch (_) {
        // トークン無効化を優先し、古いFirestore記録は送信失敗に委ねる
      }
    }

    try {
      await _messagingGateway.deleteToken();
    } catch (_) {
      // 未対応環境でも端末設定の保存は完了させる
    } finally {
      _registeredToken = null;
    }
  }

  /// トークンの取得とFirestore登録を行う。
  /// 戻り値は「実際に登録が完了したか」を示す。
  /// - トークンが取得できない(null/空)場合はfalse
  /// - 途中でセッションが古くなった場合はfalse(書き込みは行わない)
  static Future<bool> _registerCurrentToken(
    NotificationSession session,
  ) async {
    final token = await _getTokenSafely();
    if (token == null || token.isEmpty) return false;
    if (!_isSessionCurrent(session)) return false;

    await _saveToken(session, token);
    if (!_isSessionCurrent(session)) return false;

    _registeredToken = token;
    return true;
  }

  static Future<void> _startTokenRefreshListener() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messagingGateway.onTokenRefresh.listen(
      (newToken) async {
        final currentUid = _authUidProvider.currentUid;
        if (currentUid == null || newToken.isEmpty) return;
        final session = _sessionGuard.capture(currentUid);

        try {
          if (await _isPreferenceEnabled() && _isSessionCurrent(session)) {
            final previousToken = _registeredToken;
            if (previousToken != null && previousToken != newToken) {
              try {
                await _tokenStore.delete(session.uid, previousToken);
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
      return await _messagingGateway.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getExistingTokenSafely() async {
    if (_registeredToken != null && _registeredToken!.isNotEmpty) {
      return _registeredToken;
    }

    try {
      final status = await _messagingGateway.getAuthorizationStatus();
      final permissionGranted = status == AuthorizationStatus.authorized ||
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

      await _tokenStore.save(
        session.uid,
        token,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );

      if (!_isSessionCurrent(session)) {
        // 書き込み中に別セッション(ログアウト/別ユーザーへの切り替え)へ
        // 移った場合、直前に書き込んだトークンを巻き戻す。
        // これを行わないと、書き込み開始時点では最新だったセッションが
        // 完了までの間に古くなった場合に、旧uid配下へトークンが
        // 残ってしまう。
        try {
          await _tokenStore.delete(session.uid, token);
        } catch (_) {
          // 巻き戻しに失敗しても致命的ではない(次回のクリーンアップに委ねる)
        }
      }
    });
  }

  static Future<bool> _isPreferenceEnabled() async {
    return await _preferenceStore.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> _setPreferenceEnabled(bool enabled) {
    return _preferenceStore.setBool(_notificationsEnabledKey, enabled);
  }

  static bool _isSessionCurrent(NotificationSession session) {
    return _sessionGuard.isCurrent(session, _authUidProvider.currentUid);
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

}
