import 'package:firebase_messaging/firebase_messaging.dart';

/// 通知を有効化する際の、許可要求からトークン登録までの流れ。
///
/// 許可要求・設定保存・トークン登録・更新監視で発生した例外は、
/// セッションが有効な場合に端末設定を無効へ戻してから呼び出し元へ伝える。
/// 最後の状態読み込み([loadStatus])は try の外で行い、その失敗では
/// 端末設定を変更せず、そのまま呼び出し元へ伝える。
Future<T> runNotificationEnableFlow<T>({
  required Future<AuthorizationStatus> Function() requestPermission,
  required bool Function() isSessionCurrent,
  required Future<void> Function(bool enabled) setPreferenceEnabled,
  required Future<void> Function() registerCurrentToken,
  required Future<void> Function() startTokenRefreshListener,
  required Future<T> Function() loadStatus,
}) async {
  try {
    final status = await requestPermission();

    // セッションが切り替わった(ログアウト等)場合は何もせず現在の状態を返す。
    if (isSessionCurrent()) {
      if (status == AuthorizationStatus.denied) {
        await setPreferenceEnabled(false);
      } else {
        await registerCurrentToken();
        if (isSessionCurrent()) {
          await startTokenRefreshListener();
        }
      }
    }
  } catch (_) {
    if (isSessionCurrent()) {
      await setPreferenceEnabled(false);
    }
    rethrow;
  }

  return loadStatus();
}

/// 登録済みトークン、または通知が許可されている場合に取得したトークンを返す。
/// 取得できない場合や例外発生時は null を返す。
Future<String?> loadExistingNotificationToken({
  required String? registeredToken,
  required Future<AuthorizationStatus> Function() getAuthorizationStatus,
  required Future<String?> Function() getTokenSafely,
}) async {
  if (registeredToken != null && registeredToken.isNotEmpty) {
    return registeredToken;
  }

  try {
    final status = await getAuthorizationStatus();
    final permissionGranted = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    if (!permissionGranted) return null;

    return await getTokenSafely();
  } catch (_) {
    return null;
  }
}
