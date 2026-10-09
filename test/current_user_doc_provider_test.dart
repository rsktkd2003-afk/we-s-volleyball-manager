import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/current_user_doc.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';

import 'support/fake_repositories.dart';

void main() {
  late FakeCurrentUserRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<CurrentUserDocState>> sub;

  // 依存Providerの再構築とストリーム購読開始を確実に進める。
  Future<void> flush() async {
    for (var i = 0; i < 3; i++) {
      await container.pump();
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    repository = FakeCurrentUserRepository();
    container = ProviderContainer(
      overrides: [currentUserRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    sub = container.listen(currentUserDocProvider, (_, _) {});
  });

  CurrentUserDocState? current() => sub.read().valueOrNull;

  test('認証状態が確定するまでは読み込み中', () {
    expect(sub.read().isLoading, isTrue);
  });

  test('未ログインならSignedOutになる', () async {
    repository.auth.add(null);
    await flush();

    expect(current(), isA<CurrentUserSignedOut>());
  });

  test('ユーザードキュメントが存在しなければMissingになる', () async {
    repository.auth.add('u1');
    await flush();
    repository.docFor('u1').add(null);
    await flush();

    final state = current();
    expect(state, isA<CurrentUserDocMissing>());
    expect((state as CurrentUserDocMissing).uid, 'u1');
  });

  test('roleとplayerIdの更新をリアルタイムに反映する', () async {
    repository.auth.add('u1');
    await flush();

    repository.docFor('u1').add({
      'email': 'a@example.com',
      'displayName': 'A',
      'role': 'member',
      'playerId': null,
    });
    await flush();

    var user = (current() as CurrentUserDocLoaded).user;
    expect(user.uid, 'u1');
    expect(user.isAdmin, isFalse);
    expect(user.hasLinkedPlayer, isFalse);

    repository.docFor('u1').add({
      'email': 'a@example.com',
      'displayName': 'A',
      'role': 'admin',
      'playerId': 'p1',
    });
    await flush();

    user = (current() as CurrentUserDocLoaded).user;
    expect(user.isAdmin, isTrue);
    expect(user.playerId, 'p1');
    expect(user.hasLinkedPlayer, isTrue);
  });

  test('roleが未設定ならmemberとして扱う', () async {
    repository.auth.add('u1');
    await flush();
    repository.docFor('u1').add({'email': 'a@example.com'});
    await flush();

    final user = (current() as CurrentUserDocLoaded).user;
    expect(user.role, 'member');
    expect(user.playerId, isNull);
  });

  test('読み取りエラーはエラー状態として区別する', () async {
    repository.auth.add('u1');
    await flush();
    repository.docFor('u1').addError(StateError('permission-denied'));
    await flush();

    expect(sub.read().hasError, isTrue);
    expect(sub.read().error, isA<StateError>());
  });

  test('ログアウトするとSignedOutになり、ユーザードキュメントの購読を解除する',
      () async {
    repository.auth.add('u1');
    await flush();
    repository.docFor('u1').add({'role': 'admin', 'playerId': null});
    await flush();
    expect(current(), isA<CurrentUserDocLoaded>());
    expect(repository.hasActiveDocListener('u1'), isTrue);

    repository.auth.add(null);
    await flush();
    await flush();

    expect(current(), isA<CurrentUserSignedOut>());
    expect(repository.hasActiveDocListener('u1'), isFalse);
  });

  test('別ユーザーで再ログインすると新しいユーザーのドキュメントに切り替わる',
      () async {
    repository.auth.add('u1');
    await flush();
    repository.docFor('u1').add({'role': 'admin'});
    await flush();

    repository.auth.add(null);
    await flush();
    repository.auth.add('u2');
    await flush();
    repository.docFor('u2').add({'role': 'member', 'playerId': 'p2'});
    await flush();

    final user = (current() as CurrentUserDocLoaded).user;
    expect(user.uid, 'u2');
    expect(user.isAdmin, isFalse);
    expect(repository.hasActiveDocListener('u1'), isFalse);
  });

  test('認証状態の取得エラーはエラー状態として区別する', () async {
    repository.auth.addError(StateError('auth-failed'));
    await flush();

    expect(sub.read().hasError, isTrue);
  });
}
