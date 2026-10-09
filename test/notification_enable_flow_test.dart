import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/utils/notification_enable_flow.dart';

/// runNotificationEnableFlow の依存呼び出しを記録する。
class _Recorder {
  _Recorder({
    this.status = AuthorizationStatus.authorized,
    this.sessionCurrent = true,
    this.requestError,
    this.registerError,
    this.listenerError,
    this.loadError,
  });

  final AuthorizationStatus status;
  bool sessionCurrent;
  final Object? requestError;
  final Object? registerError;
  final Object? listenerError;
  final Object? loadError;

  final List<String> calls = [];
  final List<bool> preferenceWrites = [];

  Future<String> run() {
    return runNotificationEnableFlow<String>(
      requestPermission: () async {
        calls.add('requestPermission');
        if (requestError != null) throw requestError!;
        return status;
      },
      isSessionCurrent: () => sessionCurrent,
      setPreferenceEnabled: (enabled) async {
        calls.add('setPreference($enabled)');
        preferenceWrites.add(enabled);
      },
      registerCurrentToken: () async {
        calls.add('registerToken');
        if (registerError != null) throw registerError!;
      },
      startTokenRefreshListener: () async {
        calls.add('startListener');
        if (listenerError != null) throw listenerError!;
      },
      loadStatus: () async {
        calls.add('loadStatus');
        if (loadError != null) throw loadError!;
        return 'status';
      },
    );
  }
}

void main() {
  group('runNotificationEnableFlow', () {
    test('許可されるとトークンを登録し、更新監視を開始して状態を返す', () async {
      final recorder = _Recorder();

      expect(await recorder.run(), 'status');
      expect(recorder.calls, [
        'requestPermission',
        'registerToken',
        'startListener',
        'loadStatus',
      ]);
      expect(recorder.preferenceWrites, isEmpty);
    });

    test('一時許可(provisional)でもトークンを登録する', () async {
      final recorder = _Recorder(status: AuthorizationStatus.provisional);

      await recorder.run();

      expect(recorder.calls, contains('registerToken'));
      expect(recorder.preferenceWrites, isEmpty);
    });

    test('拒否されると端末設定を無効にして状態を返す', () async {
      final recorder = _Recorder(status: AuthorizationStatus.denied);

      expect(await recorder.run(), 'status');
      expect(recorder.calls, [
        'requestPermission',
        'setPreference(false)',
        'loadStatus',
      ]);
    });

    test('許可要求中にログアウトした場合は何も変更せず状態を返す', () async {
      final recorder = _Recorder(sessionCurrent: false);

      expect(await recorder.run(), 'status');
      expect(recorder.calls, ['requestPermission', 'loadStatus']);
      expect(recorder.preferenceWrites, isEmpty);
    });

    test('許可要求の失敗時は端末設定を無効にして例外を伝える', () async {
      final recorder = _Recorder(requestError: StateError('request'));

      await expectLater(recorder.run(), throwsA(isA<StateError>()));
      expect(recorder.preferenceWrites, [false]);
      expect(recorder.calls, isNot(contains('loadStatus')));
    });

    test('トークン登録の失敗時は端末設定を無効にして例外を伝える', () async {
      final recorder = _Recorder(registerError: StateError('register'));

      await expectLater(recorder.run(), throwsA(isA<StateError>()));
      expect(recorder.preferenceWrites, [false]);
      expect(recorder.calls, isNot(contains('startListener')));
    });

    test('更新監視の開始失敗時は端末設定を無効にして例外を伝える', () async {
      final recorder = _Recorder(listenerError: StateError('listener'));

      await expectLater(recorder.run(), throwsA(isA<StateError>()));
      expect(recorder.preferenceWrites, [false]);
    });

    test('ログアウト後の失敗では端末設定を変更せずに例外を伝える', () async {
      final recorder = _Recorder();

      // トークン登録中にセッションが切り替わった状況を再現する。
      final future = runNotificationEnableFlow<String>(
        requestPermission: () async => AuthorizationStatus.authorized,
        isSessionCurrent: () => recorder.sessionCurrent,
        setPreferenceEnabled: (enabled) async {
          recorder.preferenceWrites.add(enabled);
        },
        registerCurrentToken: () async {
          recorder.sessionCurrent = false;
          throw StateError('register');
        },
        startTokenRefreshListener: () async {},
        loadStatus: () async => 'status',
      );

      await expectLater(future, throwsA(isA<StateError>()));
      expect(recorder.preferenceWrites, isEmpty);
    });

    test('状態読み込みの失敗は端末設定を変更せずにそのまま伝える(従来の挙動)', () async {
      for (final status in [
        AuthorizationStatus.authorized,
        AuthorizationStatus.denied,
      ]) {
        final recorder = _Recorder(
          status: status,
          loadError: StateError('load'),
        );

        await expectLater(recorder.run(), throwsA(isA<StateError>()));
        // 拒否時の無効化(1回)以外に、失敗による追加の無効化が起きない。
        expect(
          recorder.preferenceWrites,
          status == AuthorizationStatus.denied ? [false] : isEmpty,
        );
      }
    });

    test('ログアウト後の状態読み込み失敗も端末設定を変更せずに伝える', () async {
      final recorder = _Recorder(
        sessionCurrent: false,
        loadError: StateError('load'),
      );

      await expectLater(recorder.run(), throwsA(isA<StateError>()));
      expect(recorder.preferenceWrites, isEmpty);
    });
  });

  group('loadExistingNotificationToken', () {
    test('登録済みトークンがあればそれを返し、問い合わせない', () async {
      var queried = false;

      final token = await loadExistingNotificationToken(
        registeredToken: 'registered',
        getAuthorizationStatus: () async {
          queried = true;
          return AuthorizationStatus.authorized;
        },
        getTokenSafely: () async => 'new',
      );

      expect(token, 'registered');
      expect(queried, isFalse);
    });

    test('許可済みなら取得したトークンを返す', () async {
      for (final status in [
        AuthorizationStatus.authorized,
        AuthorizationStatus.provisional,
      ]) {
        final token = await loadExistingNotificationToken(
          registeredToken: '',
          getAuthorizationStatus: () async => status,
          getTokenSafely: () async => 'token',
        );

        expect(token, 'token');
      }
    });

    test('未許可・拒否ならトークンを取得せずnullを返す', () async {
      for (final status in [
        AuthorizationStatus.denied,
        AuthorizationStatus.notDetermined,
      ]) {
        var fetched = false;
        final token = await loadExistingNotificationToken(
          registeredToken: null,
          getAuthorizationStatus: () async => status,
          getTokenSafely: () async {
            fetched = true;
            return 'token';
          },
        );

        expect(token, isNull);
        expect(fetched, isFalse);
      }
    });

    test('許可状態の取得失敗時はnullを返す', () async {
      final token = await loadExistingNotificationToken(
        registeredToken: null,
        getAuthorizationStatus: () async => throw StateError('settings'),
        getTokenSafely: () async => 'token',
      );

      expect(token, isNull);
    });

    test('トークン取得の失敗(例外)もnullとして扱う', () async {
      final token = await loadExistingNotificationToken(
        registeredToken: null,
        getAuthorizationStatus: () async => AuthorizationStatus.authorized,
        getTokenSafely: () async => throw StateError('token'),
      );

      expect(token, isNull);
    });
  });
}
