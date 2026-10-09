import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/announcement.dart';
import 'package:volleyball_app/models/player_link_request.dart';
import 'package:volleyball_app/models/team_goal.dart';
import 'package:volleyball_app/models/team_schedule.dart';
import 'package:volleyball_app/providers/bulletin_providers.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_link_request_providers.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/providers/schedule_providers.dart';
import 'package:volleyball_app/screens/app_shell.dart';

import 'support/fake_repositories.dart';

const _phone = Size(400, 900);
const _tablet = Size(900, 1000);
const _desktop = Size(1400, 1000);

void main() {
  late FakeCurrentUserRepository userRepository;
  late FakePlayerRepository playerRepository;
  late FakeScheduleReadRepository scheduleRepository;

  setUp(() {
    userRepository = FakeCurrentUserRepository()..auth.add('member-1');
    playerRepository = FakePlayerRepository();
    scheduleRepository = FakeScheduleReadRepository();
  });

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRepositoryProvider.overrideWithValue(userRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          scheduleReadRepositoryProvider.overrideWithValue(scheduleRepository),
          announcementsProvider.overrideWith(
            (ref) => Stream.value(const <Announcement>[]),
          ),
          goalsForMonthProvider.overrideWith(
            (ref, month) => Stream.value(const <TeamGoal>[]),
          ),
          pendingPlayerLinkRequestsProvider.overrideWith(
            (ref) => Stream.value(const <PlayerLinkRequest>[]),
          ),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump();
    await tester.pump();
    userRepository.docFor('member-1').add({'role': 'member', 'playerId': 'p1'});
    await tester.pumpAndSettle();
  }

  Finder navLabel(String label) {
    return find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is NavigationBar || widget is NavigationRail,
      ),
      matching: find.text(label),
    );
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(navLabel(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  TeamSchedule scheduleToday(String title) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 10);
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

  testWidgets('初期タブはホームで、4タブを表示する', (tester) async {
    await pumpShell(tester, _phone);

    for (final label in ['ホーム', '予定', '練習', 'メンバー']) {
      expect(navLabel(label), findsOneWidget);
    }
    expect(find.text("WE'S CLUB BOARD"), findsOneWidget);
    expect(find.text('ダッシュボードを準備中です'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppShellTab.home.index,
    );
  });

  testWidgets('未表示のタブは生成せず、Firestoreの購読も始めない', (tester) async {
    await pumpShell(tester, _phone);

    expect(playerRepository.controllers, isEmpty);
    expect(scheduleRepository.scheduleSubscriptionCount, 0);
    expect(find.text('PLAYER SCOUTING BOARD', skipOffstage: false), findsNothing);
    expect(find.text('TEAM SCHEDULE BOARD', skipOffstage: false), findsNothing);
  });

  testWidgets('スマホ幅(600px未満)ではBottom Navigationを表示する', (tester) async {
    await pumpShell(tester, _phone);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('タブレット幅(600〜1199px)ではNavigationRailを表示する', (tester) async {
    await pumpShell(tester, _tablet);

    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
  });

  testWidgets('PC幅(1200px以上)ではExtended NavigationRailを表示する', (tester) async {
    await pumpShell(tester, _desktop);

    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
  });

  testWidgets('境界値: 599pxはBottom Navigation、1199pxは通常Rail', (tester) async {
    await pumpShell(tester, const Size(599, 900));
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(600, 900));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1199, 900));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
  });

  testWidgets('タブを切り替えて予定・練習・メンバーへアクセスできる', (tester) async {
    await pumpShell(tester, _phone);

    await openTab(tester, '予定');
    scheduleRepository.schedules.add([scheduleToday('全体練習')]);
    scheduleRepository.templates.add([]);
    playerRepository.last.add([]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('TEAM SCHEDULE BOARD'), findsOneWidget);
    expect(find.text('全体練習'), findsWidgets);

    await openTab(tester, '練習');
    expect(find.text('PRACTICE IDEAS'), findsOneWidget);
    expect(find.text('練習案ボードを準備中です'), findsOneWidget);

    await openTab(tester, 'メンバー');
    playerRepository.last.add([
      testPlayer(id: 'p1', name: '山田', number: 3),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('PLAYER SCOUTING BOARD'), findsOneWidget);
    expect(find.text('山田'), findsOneWidget);

    await openTab(tester, 'ホーム');
    expect(find.text('ダッシュボードを準備中です'), findsOneWidget);
  });

  testWidgets('NavigationRailからもタブを切り替えられる', (tester) async {
    await pumpShell(tester, _tablet);

    await openTab(tester, 'メンバー');
    playerRepository.last.add([testPlayer(id: 'p1', name: '山田', number: 3)]);
    await tester.pumpAndSettle();

    expect(find.text('PLAYER SCOUTING BOARD'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      AppShellTab.members.index,
    );
  });

  testWidgets('タブを切り替えても画面状態と購読を維持する', (tester) async {
    await pumpShell(tester, _phone);

    await openTab(tester, 'メンバー');
    playerRepository.last.add([
      testPlayer(id: 'p1', name: '山田', number: 3),
      testPlayer(id: 'p2', name: '佐藤', number: 12),
    ]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '佐藤');
    await tester.pumpAndSettle();
    expect(find.text('山田'), findsNothing);

    await openTab(tester, '予定');
    scheduleRepository.schedules.add([]);
    scheduleRepository.templates.add([]);
    await tester.pump();
    await openTab(tester, 'ホーム');
    await openTab(tester, 'メンバー');
    await tester.pumpAndSettle();

    // 検索条件と絞り込み結果が残っている。
    expect(find.widgetWithText(TextField, '佐藤'), findsOneWidget);
    expect(find.text('山田'), findsNothing);
    // 切り替えのたびに再購読しない(予定・メンバーで選手データの購読を共有)。
    expect(playerRepository.controllers, hasLength(1));
    expect(playerRepository.hasActiveListener, isTrue);

    await openTab(tester, '予定');
    expect(scheduleRepository.scheduleSubscriptionCount, 1);
  });

  testWidgets('画面幅が変わってナビゲーションが切り替わっても画面状態を維持する',
      (tester) async {
    await pumpShell(tester, _phone);

    await openTab(tester, 'メンバー');
    playerRepository.last.add([
      testPlayer(id: 'p1', name: '山田', number: 3),
      testPlayer(id: 'p2', name: '佐藤', number: 12),
    ]);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '佐藤');
    await tester.pumpAndSettle();

    await tester.binding.setSurfaceSize(_desktop);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('PLAYER SCOUTING BOARD'), findsOneWidget);
    expect(find.widgetWithText(TextField, '佐藤'), findsOneWidget);
    expect(find.text('山田'), findsNothing);
    expect(playerRepository.controllers, hasLength(1));
  });

  testWidgets('小型スマホ幅(360px)で全タブを表示してもレイアウトが崩れない',
      (tester) async {
    await pumpShell(tester, const Size(360, 740));

    await openTab(tester, '予定');
    scheduleRepository.schedules.add([scheduleToday('全体練習')]);
    scheduleRepository.templates.add([]);
    playerRepository.last.add([
      testPlayer(id: 'p1', name: '山田', number: 3),
      testPlayer(id: 'p2', name: '佐藤', number: 12),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('TEAM SCHEDULE BOARD'), findsOneWidget);

    await openTab(tester, '練習');
    expect(find.text('PRACTICE IDEAS'), findsOneWidget);

    await openTab(tester, 'メンバー');
    await tester.pumpAndSettle();
    expect(find.text('佐藤'), findsOneWidget);

    await openTab(tester, 'ホーム');
    expect(find.text("WE'S CLUB BOARD"), findsOneWidget);
    // RenderFlex のはみ出し等が発生した場合はここで検出される。
    expect(tester.takeException(), isNull);
  });

  testWidgets('通知・設定・プロフィールの補助導線を表示する', (tester) async {
    await pumpShell(tester, _phone);

    expect(find.byTooltip('通知'), findsOneWidget);
    expect(find.byTooltip('設定'), findsOneWidget);
    expect(find.byTooltip('プロフィール'), findsOneWidget);
  });
}
