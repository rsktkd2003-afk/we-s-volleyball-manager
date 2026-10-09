import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/current_user_doc.dart';
import 'package:volleyball_app/models/team_schedule.dart';
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

  group('依存Providerの変更による再構築時の購読解除', () {
    test('playersProvider: 受信前にRepositoryが変わると古い購読を解除する', () async {
      final oldRepository = FakePlayerRepository();
      final newRepository = FakePlayerRepository();
      final container = ProviderContainer(
        overrides: [playerRepositoryProvider.overrideWithValue(oldRepository)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(playersProvider, (_, _) {});
      await settle(container);
      expect(oldRepository.hasActiveListener, isTrue);

      container.updateOverrides(
        [playerRepositoryProvider.overrideWithValue(newRepository)],
      );
      await settle(container);

      expect(newRepository.hasActiveListener, isTrue);
      expect(oldRepository.hasActiveListener, isFalse);
      expect(sub.read().isLoading, isTrue);

      oldRepository.last.add([testPlayer(id: 'old', name: '旧')]);
      await settle(container);
      expect(sub.read().isLoading, isTrue);

      newRepository.last.add([testPlayer(id: 'new', name: '新')]);
      await settle(container);
      expect(sub.read().requireValue.single.id, 'new');

      oldRepository.last.add([testPlayer(id: 'old', name: '旧')]);
      await settle(container);
      expect(sub.read().requireValue.single.id, 'new');

      sub.close();
      await settle(container);
      expect(oldRepository.hasActiveListener, isFalse);
      expect(newRepository.hasActiveListener, isFalse);
    });

    test('playersProvider: 切り替え直前に旧Streamへ送られたイベントも反映しない',
        () async {
      final oldRepository = FakePlayerRepository();
      final newRepository = FakePlayerRepository();
      final container = ProviderContainer(
        overrides: [playerRepositoryProvider.overrideWithValue(oldRepository)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(playersProvider, (_, _) {});
      await settle(container);

      // 旧Streamのイベント配信前(同期的)に依存Providerを変更する。
      oldRepository.last.add([testPlayer(id: 'old', name: '旧')]);
      container.updateOverrides(
        [playerRepositoryProvider.overrideWithValue(newRepository)],
      );
      // 再構築を同期的に確定させる。
      sub.read();
      await settle(container);

      expect(sub.read().isLoading, isTrue);
      expect(oldRepository.hasActiveListener, isFalse);

      newRepository.last.add([testPlayer(id: 'new', name: '新')]);
      await settle(container);
      expect(sub.read().requireValue.single.id, 'new');
    });

    test('schedulesProvider: 受信前にRepositoryが変わると古い購読を解除する',
        () async {
      final oldRepository = FakeScheduleReadRepository();
      final newRepository = FakeScheduleReadRepository();
      final container = ProviderContainer(
        overrides: [
          scheduleReadRepositoryProvider.overrideWithValue(oldRepository),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(schedulesProvider, (_, _) {});
      await settle(container);
      expect(oldRepository.hasActiveScheduleListener, isTrue);

      container.updateOverrides(
        [scheduleReadRepositoryProvider.overrideWithValue(newRepository)],
      );
      await settle(container);

      expect(newRepository.hasActiveScheduleListener, isTrue);
      expect(oldRepository.hasActiveScheduleListener, isFalse);
      expect(sub.read().isLoading, isTrue);

      oldRepository.schedules.add([_schedule('old')]);
      await settle(container);
      expect(sub.read().isLoading, isTrue);

      newRepository.schedules.add([_schedule('new')]);
      await settle(container);
      expect(sub.read().requireValue.single.id, 'new');

      oldRepository.schedules.add([_schedule('old')]);
      await settle(container);
      expect(sub.read().requireValue.single.id, 'new');

      sub.close();
      await settle(container);
      expect(oldRepository.hasActiveScheduleListener, isFalse);
      expect(newRepository.hasActiveScheduleListener, isFalse);
    });

    test('authUidProvider: 受信前にRepositoryが変わると古い購読を解除する',
        () async {
      final oldRepository = FakeCurrentUserRepository();
      final newRepository = FakeCurrentUserRepository();
      final container = ProviderContainer(
        overrides: [
          currentUserRepositoryProvider.overrideWithValue(oldRepository),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authUidProvider, (_, _) {});
      await settle(container);
      expect(oldRepository.auth.hasListener, isTrue);

      container.updateOverrides(
        [currentUserRepositoryProvider.overrideWithValue(newRepository)],
      );
      await settle(container);

      expect(newRepository.auth.hasListener, isTrue);
      expect(oldRepository.auth.hasListener, isFalse);
      expect(sub.read().isLoading, isTrue);

      oldRepository.auth.add('old-user');
      await settle(container);
      expect(sub.read().isLoading, isTrue);

      newRepository.auth.add('new-user');
      await settle(container);
      expect(sub.read().requireValue, 'new-user');

      oldRepository.auth.add('old-user');
      await settle(container);
      expect(sub.read().requireValue, 'new-user');

      sub.close();
      await settle(container);
      expect(oldRepository.auth.hasListener, isFalse);
      expect(newRepository.auth.hasListener, isFalse);
    });

    test('currentUserDocProvider: ドキュメント受信前にuidが変わると旧ユーザーの購読を解除する',
        () async {
      final repository = FakeCurrentUserRepository();
      final container = ProviderContainer(
        overrides: [currentUserRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(currentUserDocProvider, (_, _) {});
      repository.auth.add('u1');
      await settle(container);
      expect(repository.hasActiveDocListener('u1'), isTrue);

      repository.auth.add('u2');
      await settle(container);

      expect(repository.hasActiveDocListener('u2'), isTrue);
      expect(repository.hasActiveDocListener('u1'), isFalse);
      expect(sub.read().isLoading, isTrue);

      repository.docFor('u1').add({'role': 'admin'});
      await settle(container);
      expect(sub.read().isLoading, isTrue);

      repository.docFor('u2').add({'role': 'member'});
      await settle(container);
      final loaded = sub.read().requireValue as CurrentUserDocLoaded;
      expect(loaded.user.uid, 'u2');
      expect(loaded.user.isAdmin, isFalse);

      repository.docFor('u1').add({'role': 'admin'});
      await settle(container);
      final stillLoaded = sub.read().requireValue as CurrentUserDocLoaded;
      expect(stillLoaded.user.uid, 'u2');
      expect(stillLoaded.user.isAdmin, isFalse);

      sub.close();
      await settle(container);
      expect(repository.hasActiveDocListener('u1'), isFalse);
      expect(repository.hasActiveDocListener('u2'), isFalse);
      expect(repository.auth.hasListener, isFalse);
    });

    test('currentUserDocProvider: 受信前にRepositoryが変わると旧Repositoryの購読をすべて解除する',
        () async {
      final oldRepository = FakeCurrentUserRepository()..auth.add('u1');
      final newRepository = FakeCurrentUserRepository()..auth.add('u1');
      final container = ProviderContainer(
        overrides: [
          currentUserRepositoryProvider.overrideWithValue(oldRepository),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(currentUserDocProvider, (_, _) {});
      await settle(container);
      expect(oldRepository.hasActiveDocListener('u1'), isTrue);

      container.updateOverrides(
        [currentUserRepositoryProvider.overrideWithValue(newRepository)],
      );
      await settle(container);

      expect(newRepository.hasActiveDocListener('u1'), isTrue);
      expect(oldRepository.hasActiveDocListener('u1'), isFalse);
      expect(oldRepository.auth.hasListener, isFalse);

      oldRepository.docFor('u1').add({'role': 'admin'});
      await settle(container);
      expect(sub.read().isLoading, isTrue);

      newRepository.docFor('u1').add({'role': 'member'});
      await settle(container);
      expect(
        (sub.read().requireValue as CurrentUserDocLoaded).user.isAdmin,
        isFalse,
      );

      sub.close();
      await settle(container);
      expect(oldRepository.hasActiveDocListener('u1'), isFalse);
      expect(newRepository.hasActiveDocListener('u1'), isFalse);
      expect(oldRepository.auth.hasListener, isFalse);
      expect(newRepository.auth.hasListener, isFalse);
    });
  });
}

TeamSchedule _schedule(String id) {
  final start = DateTime(2026, 10, 1, 18);
  return TeamSchedule(
    id: id,
    title: '練習',
    location: '体育館',
    start: start,
    end: start.add(const Duration(hours: 2)),
    durationMinutes: 120,
    color: Colors.blue,
  );
}
