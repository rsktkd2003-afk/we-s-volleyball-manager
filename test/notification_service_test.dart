import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/services/notification_dependencies.dart';
import 'package:volleyball_app/services/notification_service.dart';

class FakeAuthUidProvider implements AuthUidProvider {
  String? uid;

  @override
  String? get currentUid => uid;
}

class FakeMessagingGateway implements MessagingGateway {
  AuthorizationStatus permissionResult = AuthorizationStatus.authorized;
  Object? requestPermissionError;
  String? tokenResult = 'token-1';

  Completer<String?>? getTokenGate;
  void Function()? onGetTokenCalled;

  int requestPermissionCalls = 0;
  int getTokenCalls = 0;
  int deleteTokenCalls = 0;

  final StreamController<String> _refreshController =
      StreamController<String>.broadcast();

  @override
  Future<AuthorizationStatus> requestPermission() async {
    requestPermissionCalls++;
    if (requestPermissionError != null) {
      throw requestPermissionError!;
    }
    return permissionResult;
  }

  @override
  Future<AuthorizationStatus> getAuthorizationStatus() async =>
      permissionResult;

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    onGetTokenCalled?.call();
    if (getTokenGate != null) {
      return getTokenGate!.future;
    }
    return tokenResult;
  }

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
  }

  @override
  Stream<String> get onTokenRefresh => _refreshController.stream;

  void emitTokenRefresh(String token) => _refreshController.add(token);

  Future<void> dispose() => _refreshController.close();
}

class FakeTokenStore implements TokenStore {
  final Map<String, Set<String>> savedTokens = {};
  final List<String> saveLog = [];
  final List<String> deleteLog = [];

  Completer<void>? saveGate;
  void Function()? onSaveCalled;
  bool throwOnSave = false;

  @override
  Future<void> save(String uid, String token, {required String platform}) async {
    saveLog.add('$uid:$token');
    onSaveCalled?.call();
    if (saveGate != null) {
      await saveGate!.future;
    }
    if (throwOnSave) {
      throw Exception('firestore save failed');
    }
    savedTokens.putIfAbsent(uid, () => <String>{}).add(token);
  }

  @override
  Future<void> delete(String uid, String token) async {
    deleteLog.add('$uid:$token');
    savedTokens[uid]?.remove(token);
  }
}

class FakePreferenceStore implements PreferenceStore {
  final Map<String, bool> values = {};

  @override
  Future<bool?> getBool(String key) async => values[key];

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }
}

void main() {
  late FakeAuthUidProvider fakeAuth;
  late FakeMessagingGateway fakeMessaging;
  late FakeTokenStore fakeTokenStore;
  late FakePreferenceStore fakePreferences;

  setUp(() {
    fakeAuth = FakeAuthUidProvider();
    fakeMessaging = FakeMessagingGateway();
    fakeTokenStore = FakeTokenStore();
    fakePreferences = FakePreferenceStore();

    NotificationService.configureForTesting(
      authUidProvider: fakeAuth,
      messagingGateway: fakeMessaging,
      tokenStore: fakeTokenStore,
      preferenceStore: fakePreferences,
    );
  });

  tearDown(() async {
    await NotificationService.resetForTesting();
    await fakeMessaging.dispose();
  });

  test('1: Aのinitialize中にログアウトした場合、Aへトークンを書き込まない', () async {
    fakeAuth.uid = 'user-a';
    final started = Completer<void>();
    fakeMessaging.getTokenGate = Completer<String?>();
    fakeMessaging.onGetTokenCalled = () {
      if (!started.isCompleted) started.complete();
    };

    final initializeFuture = NotificationService.initialize();
    await started.future;

    // ユーザーAがログアウトする。detachCurrentUser自身もgetTokenを
    // 参照しうるため、ここでは同期的にawaitせず後でまとめて解決する。
    fakeAuth.uid = null;
    final detachFuture = NotificationService.detachCurrentUser();

    // ログアウト後にトークン取得が完了する(initialize処理の再開)。
    fakeMessaging.getTokenGate!.complete('token-a');
    await initializeFuture;
    await detachFuture;

    expect(fakeTokenStore.savedTokens['user-a'], isNull);
  });

  test('2: Aのinitialize中にBへ切り替わった場合、Aへ書き込まない', () async {
    fakeAuth.uid = 'user-a';
    final started = Completer<void>();
    fakeMessaging.getTokenGate = Completer<String?>();
    fakeMessaging.onGetTokenCalled = () {
      if (!started.isCompleted) started.complete();
    };

    final initializeAFuture = NotificationService.initialize();
    await started.future;

    // Aがログアウトし、Bがログインする。detachCurrentUser自身も
    // getTokenを参照しうるため、ここでは同期的にawaitしない。
    fakeAuth.uid = null;
    final detachFuture = NotificationService.detachCurrentUser();

    fakeAuth.uid = 'user-b';
    fakeMessaging.tokenResult = 'token-b';
    final pendingGate = fakeMessaging.getTokenGate;
    fakeMessaging.getTokenGate = null; // BのgetTokenは即座に解決させる
    await NotificationService.initialize();

    // Aの遅延していたinitializeとdetachCurrentUserが再開する。
    pendingGate!.complete('token-a');
    await initializeAFuture;
    await detachFuture;

    expect(fakeTokenStore.savedTokens['user-a'], isNull);
    expect(fakeTokenStore.savedTokens['user-b'], contains('token-b'));
  });

  test('3: Bのinitializeのみ Bへ登録される', () async {
    fakeAuth.uid = 'user-b';
    fakeMessaging.tokenResult = 'token-b';

    await NotificationService.initialize();

    expect(fakeTokenStore.savedTokens['user-b'], contains('token-b'));
    expect(fakeTokenStore.savedTokens['user-a'], isNull);
  });

  test('4: token refresh listenerが古いuidへ書き込まない', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.tokenResult = 'token-a';
    await NotificationService.initialize();
    expect(fakeTokenStore.savedTokens['user-a'], contains('token-a'));

    // リフレッシュされた新トークンの保存を、書き込み直前で一時停止する。
    final saveStarted = Completer<void>();
    fakeTokenStore.saveGate = Completer<void>();
    fakeTokenStore.onSaveCalled = () {
      if (!saveStarted.isCompleted) saveStarted.complete();
    };

    fakeMessaging.emitTokenRefresh('token-a-refreshed');
    await saveStarted.future;

    // 保存が完了する前に、別ユーザーへ切り替わる。
    fakeAuth.uid = 'user-b';

    fakeTokenStore.saveGate!.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(fakeTokenStore.savedTokens['user-a'], isNot(contains('token-a-refreshed')));
  });

  test('5: ログアウト時に対象トークンが削除される', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.tokenResult = 'token-a';
    await NotificationService.initialize();
    expect(fakeTokenStore.savedTokens['user-a'], contains('token-a'));

    await NotificationService.detachCurrentUser();

    expect(fakeTokenStore.savedTokens['user-a'], isNot(contains('token-a')));
    expect(fakeTokenStore.deleteLog, contains('user-a:token-a'));
  });

  test('6: ログアウト後、遅延していたinitializeがトークンを再作成しない', () async {
    fakeAuth.uid = 'user-a';
    final started = Completer<void>();
    fakeMessaging.getTokenGate = Completer<String?>();
    fakeMessaging.onGetTokenCalled = () {
      if (!started.isCompleted) started.complete();
    };

    final initializeFuture = NotificationService.initialize();
    await started.future;

    // トークン登録が完了する前にログアウトする(この時点でFirestoreには何も無い)。
    // detachCurrentUser自身もgetTokenを参照しうるため、同期的にawaitしない。
    fakeAuth.uid = null;
    final detachFuture = NotificationService.detachCurrentUser();

    // 遅延していたinitializeとdetachCurrentUserがようやく再開する。
    fakeMessaging.getTokenGate!.complete('token-a');
    await initializeFuture;
    await detachFuture;

    expect(fakeTokenStore.savedTokens['user-a'], isNull);
  });

  test('7: setEnabled(true)成功時のみ設定がtrueになる', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.tokenResult = 'token-a';

    final status = await NotificationService.setEnabled(true);

    expect(fakePreferences.values['notifications_enabled'], isTrue);
    expect(status.preferenceEnabled, isTrue);
    expect(fakeTokenStore.savedTokens['user-a'], contains('token-a'));
  });

  test('8: requestPermission失敗時に設定がfalseへ戻る', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.requestPermissionError = Exception('permission error');

    await expectLater(
      NotificationService.setEnabled(true),
      throwsA(isA<Exception>()),
    );

    expect(fakePreferences.values['notifications_enabled'], isFalse);
  });

  test('9: getToken失敗時に設定がfalseへ戻る', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.tokenResult = null;

    final status = await NotificationService.setEnabled(true);

    expect(fakePreferences.values['notifications_enabled'], isFalse);
    expect(status.preferenceEnabled, isFalse);
  });

  test('10: Firestore登録失敗時に設定がfalseへ戻る', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.tokenResult = 'token-a';
    fakeTokenStore.throwOnSave = true;

    await expectLater(
      NotificationService.setEnabled(true),
      throwsA(isA<Exception>()),
    );

    expect(fakePreferences.values['notifications_enabled'], isFalse);
  });

  test('11: setEnabled(false)でFirestoreトークンとFCMトークンが適切に解除される', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.tokenResult = 'token-a';
    await NotificationService.setEnabled(true);
    expect(fakeTokenStore.savedTokens['user-a'], contains('token-a'));

    await NotificationService.setEnabled(false);

    expect(fakeTokenStore.savedTokens['user-a'], isNot(contains('token-a')));
    expect(fakeMessaging.deleteTokenCalls, 1);
    expect(fakePreferences.values['notifications_enabled'], isFalse);
  });

  test('12: initializeの多重実行でリスナーが重複しない', () async {
    fakeAuth.uid = 'user-a';
    fakeMessaging.tokenResult = 'token-a';

    await NotificationService.initialize();
    await NotificationService.initialize();

    fakeMessaging.emitTokenRefresh('token-a-refreshed');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final refreshedSaveCount = fakeTokenStore.saveLog
        .where((entry) => entry == 'user-a:token-a-refreshed')
        .length;
    expect(refreshedSaveCount, 1);
  });
}
