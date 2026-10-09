import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/announcement.dart';
import 'package:volleyball_app/models/team_goal.dart';
import 'package:volleyball_app/models/team_schedule.dart';
import 'package:volleyball_app/providers/bulletin_providers.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/providers/schedule_providers.dart';
import 'package:volleyball_app/screens/schedule_screen.dart';

import 'support/fake_repositories.dart';

void main() {
  late FakeScheduleReadRepository scheduleRepository;
  late FakePlayerRepository playerRepository;
  late FakeCurrentUserRepository userRepository;
  late ValueNotifier<bool> visible;

  setUp(() {
    scheduleRepository = FakeScheduleReadRepository();
    playerRepository = FakePlayerRepository();
    userRepository = FakeCurrentUserRepository()..auth.add('member-1');
    visible = ValueNotifier<bool>(true);
  });

  tearDown(() => visible.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleReadRepositoryProvider.overrideWithValue(scheduleRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          currentUserRepositoryProvider.overrideWithValue(userRepository),
          announcementsProvider.overrideWith(
            (ref) => Stream.value(const <Announcement>[]),
          ),
          goalsForMonthProvider.overrideWith(
            (ref, month) => Stream.value(const <TeamGoal>[]),
          ),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, value, _) => value
                ? const ScheduleScreen()
                : const Scaffold(body: Text('別画面')),
          ),
        ),
      ),
    );
  }

  /// SnackBarを順に消化しながら対象の文言が表示されるか確認する。
  Future<bool> waitForSnackBarText(WidgetTester tester, String text) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.textContaining(text).evaluate().isNotEmpty) return true;
      await tester.pump(const Duration(seconds: 5));
    }
    return false;
  }

  TeamSchedule scheduleOn(DateTime day, String title) {
    final start = DateTime(day.year, day.month, day.day, 10);
    return TeamSchedule(
      id: 'id-$title',
      title: title,
      location: '体育館',
      start: start,
      end: start.add(const Duration(hours: 2)),
      durationMinutes: 120,
      color: Colors.blue,
    );
  }

  testWidgets('既存の予定一覧をカレンダーに表示する', (tester) async {
    await pumpScreen(tester);

    final today = DateTime.now();
    scheduleRepository.schedules.add([scheduleOn(today, '全体練習')]);
    scheduleRepository.templates.add([]);
    playerRepository.last.add([]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('TEAM SCHEDULE BOARD'), findsOneWidget);
    expect(find.text('全体練習'), findsWidgets);
  });

  testWidgets('予定の更新をカレンダーへ反映する', (tester) async {
    await pumpScreen(tester);

    final today = DateTime.now();
    scheduleRepository.schedules.add([scheduleOn(today, '全体練習')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('全体練習'), findsWidgets);

    scheduleRepository.schedules.add([scheduleOn(today, '練習試合')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('練習試合'), findsWidgets);
    expect(find.text('全体練習'), findsNothing);
  });

  testWidgets('予定の読み取りエラーをSnackBarで通知する', (tester) async {
    await pumpScreen(tester);

    scheduleRepository.schedules.addError(StateError('schedules-unavailable'));

    expect(
      await waitForSnackBarText(tester, 'schedules-unavailable'),
      isTrue,
    );
  });

  testWidgets('管理者判定の取得エラーを従来通りSnackBarで通知する', (tester) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    userRepository.docFor('member-1').addError(StateError('user-doc-error'));

    expect(await waitForSnackBarText(tester, 'user-doc-error'), isTrue);
  });

  testWidgets('画面が破棄されると予定・テンプレート・選手の購読を解除する', (tester) async {
    await pumpScreen(tester);
    scheduleRepository.schedules.add([]);
    scheduleRepository.templates.add([]);
    playerRepository.last.add([]);
    await tester.pump();
    expect(scheduleRepository.hasActiveScheduleListener, isTrue);
    expect(scheduleRepository.hasActiveTemplateListener, isTrue);
    expect(playerRepository.hasActiveListener, isTrue);

    visible.value = false;
    await tester.pump();
    await tester.pump();

    expect(find.text('別画面'), findsOneWidget);
    expect(scheduleRepository.hasActiveScheduleListener, isFalse);
    expect(scheduleRepository.hasActiveTemplateListener, isFalse);
    expect(playerRepository.hasActiveListener, isFalse);

    // SnackBar等の保留中タイマーを消化する。
    await tester.pump(const Duration(seconds: 10));
  });
}
