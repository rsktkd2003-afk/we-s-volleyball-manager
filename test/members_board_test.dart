import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/announcement.dart';
import 'package:volleyball_app/models/player.dart';
import 'package:volleyball_app/models/player_issue.dart';
import 'package:volleyball_app/models/player_link_request.dart';
import 'package:volleyball_app/models/team_goal.dart';
import 'package:volleyball_app/providers/bulletin_providers.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_issue_providers.dart';
import 'package:volleyball_app/providers/player_link_request_providers.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/providers/schedule_providers.dart';
import 'package:volleyball_app/screens/app_shell.dart';
import 'package:volleyball_app/screens/members_screen.dart';
import 'package:volleyball_app/screens/player_detail_screen.dart';
import 'package:volleyball_app/widgets/player_filter_bar.dart';

import 'support/fake_repositories.dart';

const _longName = 'アレクサンダー・ヴァン・デル・ベルク・ジュニア・三世';

Player _player({
  required String id,
  required String name,
  int number = 0,
  String position = 'WS',
  String grade = '1年',
  List<String> roles = const [],
}) {
  return Player(
    id: id,
    name: name,
    number: number,
    position: position,
    dominantHand: '右',
    grade: grade,
    height: 175,
    weight: 65,
    standingReach: 225,
    maxReach: 305,
    blockReach: 295,
    roles: roles,
  );
}

Player _unsetPlayer() {
  return Player(
    id: 'unset',
    name: '',
    number: 0,
    position: '未設定',
    dominantHand: '右',
    grade: '未設定',
    height: 0,
    weight: 0,
    standingReach: 0,
    maxReach: 0,
    blockReach: 0,
  );
}

List<Player> _roster() => [
      _player(id: 'p1', name: '山田', number: 12, position: 'MB', grade: '2年'),
      _player(id: 'p2', name: '佐藤', number: 3, position: 'WS', grade: '1年'),
      _player(
        id: 'p3',
        name: '安藤',
        number: 7,
        position: 'S',
        grade: '3年',
        roles: const ['captain', 'sns', 'contact'],
      ),
    ];

/// 2つのテキストの表示順(上→下、左→右)を比較する。
bool _appearsBefore(WidgetTester tester, String a, String b) {
  final pa = tester.getTopLeft(find.text(a));
  final pb = tester.getTopLeft(find.text(b));
  if ((pa.dy - pb.dy).abs() > 1) return pa.dy < pb.dy;
  return pa.dx < pb.dx;
}

void main() {
  late FakePlayerRepository repository;

  setUp(() {
    repository = FakePlayerRepository();
  });

  Future<void> pumpMembers(
    WidgetTester tester, {
    Size size = const Size(1280, 1600),
    List<Player>? players,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
          currentUserRepositoryProvider.overrideWithValue(
            FakeCurrentUserRepository()..auth.add('member-1'),
          ),
          playerIssuesProvider.overrideWith(
            (ref, playerId) => Stream.value(const <PlayerIssue>[]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: MembersScreen())),
      ),
    );
    repository.last.add(players ?? _roster());
    await tester.pumpAndSettle();
  }

  Future<void> selectDropdown(
    WidgetTester tester,
    int index,
    String value,
  ) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(index));
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  group('メンバー一覧', () {
    testWidgets('見出し・件数・選手カードを表示する', (tester) async {
      await pumpMembers(tester);

      expect(find.text('PLAYER SCOUTING BOARD'), findsOneWidget);
      expect(find.text('3名'), findsOneWidget);
      for (final name in ['山田', '佐藤', '安藤']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('NEW PLAYER'), findsOneWidget);
      // 既定は背番号順。
      expect(_appearsBefore(tester, '佐藤', '安藤'), isTrue);
      expect(_appearsBefore(tester, '安藤', '山田'), isTrue);
    });

    testWidgets('名前検索で絞り込み、件数を表示する', (tester) async {
      await pumpMembers(tester);

      await tester.enterText(find.byType(TextField).first, '山');
      await tester.pumpAndSettle();

      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsNothing);
      expect(find.text('1名を表示中 / 全3名'), findsOneWidget);
    });

    testWidgets('学年で絞り込める', (tester) async {
      await pumpMembers(tester);

      await selectDropdown(tester, 0, '2年');

      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsNothing);
      expect(find.text('安藤'), findsNothing);
    });

    testWidgets('ポジションで絞り込める', (tester) async {
      await pumpMembers(tester);

      await selectDropdown(tester, 1, 'S');

      expect(find.text('安藤'), findsOneWidget);
      expect(find.text('山田'), findsNothing);
      expect(find.text('佐藤'), findsNothing);
    });

    testWidgets('学年順・名前順に並び替えられる', (tester) async {
      await pumpMembers(tester);

      await selectDropdown(tester, 2, '学年');
      expect(_appearsBefore(tester, '佐藤', '山田'), isTrue);
      expect(_appearsBefore(tester, '山田', '安藤'), isTrue);

      await selectDropdown(tester, 2, '名前');
      // 文字コード順(既存の compareTo)。
      final sorted = ['山田', '佐藤', '安藤']..sort();
      expect(_appearsBefore(tester, sorted[0], sorted[1]), isTrue);
      expect(_appearsBefore(tester, sorted[1], sorted[2]), isTrue);
    });

    testWidgets('スマホ幅では検索欄を常に表示し、条件は折りたたむ', (tester) async {
      await pumpMembers(tester, size: const Size(360, 1600));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('絞り込み'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);

      await tester.tap(find.text('絞り込み'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));

      await selectDropdown(tester, 0, '2年');
      expect(find.text('絞り込み (1)'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsNothing);

      // 閉じても条件は維持される。
      await tester.tap(find.text('絞り込み (1)'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text('佐藤'), findsNothing);
    });

    testWidgets('長い選手名でもカードからはみ出さない', (tester) async {
      for (final size in const [Size(360, 1600), Size(1280, 1600)]) {
        repository = FakePlayerRepository();
        await pumpMembers(
          tester,
          size: size,
          players: [
            _player(id: 'long', name: _longName, number: 99),
            ..._roster(),
          ],
        );

        expect(find.text(_longName), findsOneWidget);
        final text = tester.widget<Text>(find.text(_longName));
        expect(text.maxLines, 2);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('データ未設定の選手は未設定と表示する', (tester) async {
      await pumpMembers(tester, players: [_unsetPlayer()]);

      expect(find.text('名前未設定'), findsOneWidget);
      expect(find.text('未設定'), findsWidgets);
      // 身長・最高到達点が未入力なら数値ではなく「—」。
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('0cm'), findsNothing);
    });

    testWidgets('カードをタップすると選手詳細へ遷移する', (tester) async {
      await pumpMembers(tester);

      await tester.tap(find.text('山田'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerDetailScreen), findsOneWidget);
      expect(find.text('スカウトカード'), findsOneWidget);
      expect(find.text('改善点'), findsOneWidget);
    });
  });

  group('AppShell上のメンバータブ', () {
    late FakeScheduleReadRepository scheduleRepository;

    Future<void> pumpShell(WidgetTester tester, Size size) async {
      scheduleRepository = FakeScheduleReadRepository();
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final userRepository = FakeCurrentUserRepository()..auth.add('member-1');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRepositoryProvider.overrideWithValue(userRepository),
            playerRepositoryProvider.overrideWithValue(repository),
            scheduleReadRepositoryProvider.overrideWithValue(
              scheduleRepository,
            ),
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
      userRepository.docFor('member-1').add({'role': 'member'});
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is NavigationBar || w is NavigationRail,
          ),
          matching: find.text('メンバー'),
        ),
      );
      await tester.pump();
      repository.last.add([
        _player(
          id: 'long',
          name: _longName,
          number: 99,
          roles: const ['captain', 'viceCaptain', 'sns'],
        ),
        _unsetPlayer(),
        ..._roster(),
      ]);
      await tester.pumpAndSettle();
    }

    PlayerFilterLayout currentLayout(WidgetTester tester) {
      return tester
          .widget<PlayerFilterBar>(find.byType(PlayerFilterBar))
          .layout;
    }

    // 画面幅と、そのときの一覧幅に応じた絞り込みの配置。
    // (600px以上は NavigationRail の分だけ一覧幅が狭くなる)
    for (final (width, layout) in const [
      (360.0, PlayerFilterLayout.compact),
      (400.0, PlayerFilterLayout.compact),
      (599.0, PlayerFilterLayout.compact),
      (600.0, PlayerFilterLayout.compact),
      (900.0, PlayerFilterLayout.inline),
      (1200.0, PlayerFilterLayout.panel),
      (1440.0, PlayerFilterLayout.panel),
    ]) {
      testWidgets('${width.toInt()}px幅で崩れずに表示する', (tester) async {
        await pumpShell(tester, Size(width, 1000));

        expect(find.text('PLAYER SCOUTING BOARD'), findsOneWidget);
        expect(find.text(_longName), findsOneWidget);
        expect(find.text('名前未設定'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(currentLayout(tester), layout);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('検索・絞り込み・開閉状態はタブを切り替えても維持する', (tester) async {
      await pumpShell(tester, const Size(400, 1000));

      await tester.enterText(find.byType(TextField), '山');
      await tester.tap(find.text('絞り込み'));
      await tester.pumpAndSettle();
      await selectDropdown(tester, 0, '2年');
      expect(find.text('山田'), findsOneWidget);

      for (final label in ['予定', 'メンバー']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '山'), findsOneWidget);
      expect(find.text('絞り込み (1)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsNothing);
      expect(find.text('1名を表示中 / 全5名'), findsOneWidget);
    });
  });
}
