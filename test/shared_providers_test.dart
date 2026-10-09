import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/schedule_template.dart';
import 'package:volleyball_app/models/team_schedule.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/providers/schedule_providers.dart';

import 'support/fake_repositories.dart';

void main() {
  group('playersProvider', () {
    late FakePlayerRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakePlayerRepository();
      container = ProviderContainer(
        overrides: [playerRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
    });

    test('最初は読み込み中で、受信した選手一覧を返す', () async {
      final sub = container.listen(playersProvider, (_, _) {});
      expect(sub.read(), isA<AsyncLoading<dynamic>>());

      repository.last.add([testPlayer(id: 'p1', name: '山田')]);
      await Future<void>.delayed(Duration.zero);

      final players = sub.read().requireValue;
      expect(players.map((p) => p.id), ['p1']);
      expect(players.single.name, '山田');
    });

    test('読み取りエラーをエラー状態として返す', () async {
      final sub = container.listen(playersProvider, (_, _) {});

      repository.last.addError(StateError('permission-denied'));
      await Future<void>.delayed(Duration.zero);

      expect(sub.read().hasError, isTrue);
      expect(sub.read().error, isA<StateError>());
    });

    test('購読者がいなくなるとFirestoreの購読を解除する', () async {
      final sub = container.listen(playersProvider, (_, _) {});
      expect(repository.hasActiveListener, isTrue);
      repository.last.add([]);
      await Future<void>.delayed(Duration.zero);

      sub.close();
      await container.pump();
      await Future<void>.delayed(Duration.zero);

      expect(repository.hasActiveListener, isFalse);
    });
  });

  group('schedulesProvider', () {
    late FakeScheduleReadRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeScheduleReadRepository();
      container = ProviderContainer(
        overrides: [
          scheduleReadRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
    });

    TeamSchedule schedule(String id, DateTime start) {
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

    test('受信した予定一覧を順序を保って返す', () async {
      final sub = container.listen(schedulesProvider, (_, _) {});
      expect(sub.read().isLoading, isTrue);

      repository.schedules.add([
        schedule('s1', DateTime(2026, 10, 1, 18)),
        schedule('s2', DateTime(2026, 10, 8, 18)),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(sub.read().requireValue.map((s) => s.id), ['s1', 's2']);
    });

    test('読み取りエラーをエラー状態として返す', () async {
      final sub = container.listen(schedulesProvider, (_, _) {});

      repository.schedules.addError(StateError('unavailable'));
      await Future<void>.delayed(Duration.zero);

      expect(sub.read().hasError, isTrue);
    });

    test('scheduleTemplatesProviderはテンプレート一覧を返す', () async {
      final sub = container.listen(scheduleTemplatesProvider, (_, _) {});

      repository.templates.add([
        ScheduleTemplate(
          id: 't1',
          title: '通常練習',
          location: '体育館',
          durationMinutes: 180,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(sub.read().requireValue.single.title, '通常練習');
    });

    test('購読者がいなくなるとFirestoreの購読を解除する', () async {
      final schedulesSub = container.listen(schedulesProvider, (_, _) {});
      final templatesSub =
          container.listen(scheduleTemplatesProvider, (_, _) {});
      expect(repository.hasActiveScheduleListener, isTrue);
      expect(repository.hasActiveTemplateListener, isTrue);
      repository.schedules.add([]);
      repository.templates.add([]);
      await Future<void>.delayed(Duration.zero);

      schedulesSub.close();
      templatesSub.close();
      await container.pump();
      await Future<void>.delayed(Duration.zero);

      expect(repository.hasActiveScheduleListener, isFalse);
      expect(repository.hasActiveTemplateListener, isFalse);
    });
  });
}
