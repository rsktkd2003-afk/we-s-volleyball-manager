import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/providers/schedule_providers.dart';

import 'support/fake_repositories.dart';

/// 初回データ受信前に購読者がいなくなった場合でも、
/// 元Streamの購読(onCancel)が即座に解除されることを検証する。
void main() {
  Future<void> settle(ProviderContainer container) async {
    for (var i = 0; i < 3; i++) {
      await container.pump();
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('初回データ受信前の購読解除', () {
    test('playersProvider', () async {
      final repository = FakePlayerRepository();
      final container = ProviderContainer(
        overrides: [playerRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(playersProvider, (_, _) {});
      await settle(container);
      expect(repository.hasActiveListener, isTrue);

      sub.close();
      await settle(container);

      expect(repository.hasActiveListener, isFalse);
    });

    test('schedulesProvider / scheduleTemplatesProvider', () async {
      final repository = FakeScheduleReadRepository();
      final container = ProviderContainer(
        overrides: [
          scheduleReadRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final schedulesSub = container.listen(schedulesProvider, (_, _) {});
      final templatesSub =
          container.listen(scheduleTemplatesProvider, (_, _) {});
      await settle(container);
      expect(repository.hasActiveScheduleListener, isTrue);
      expect(repository.hasActiveTemplateListener, isTrue);

      schedulesSub.close();
      templatesSub.close();
      await settle(container);

      expect(repository.hasActiveScheduleListener, isFalse);
      expect(repository.hasActiveTemplateListener, isFalse);
    });

    test('authUidProvider', () async {
      final repository = FakeCurrentUserRepository();
      final container = ProviderContainer(
        overrides: [currentUserRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authUidProvider, (_, _) {});
      await settle(container);
      expect(repository.auth.hasListener, isTrue);

      sub.close();
      await settle(container);

      expect(repository.auth.hasListener, isFalse);
    });

    test('currentUserDocProvider (ユーザードキュメント受信前)', () async {
      final repository = FakeCurrentUserRepository();
      final container = ProviderContainer(
        overrides: [currentUserRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(currentUserDocProvider, (_, _) {});
      repository.auth.add('u1');
      await settle(container);
      expect(repository.hasActiveDocListener('u1'), isTrue);

      sub.close();
      await settle(container);

      expect(repository.hasActiveDocListener('u1'), isFalse);
      expect(repository.auth.hasListener, isFalse);
    });
  });
}
