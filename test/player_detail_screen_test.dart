import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/player.dart';
import 'package:volleyball_app/models/player_issue.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_issue_providers.dart';
import 'package:volleyball_app/screens/player_detail_screen.dart';
import 'package:volleyball_app/widgets/ability_radar_chart.dart';

import 'support/fake_repositories.dart';

const _longName = 'アレクサンダー・ヴァン・デル・ベルク・ジュニア・三世';

Player _fullPlayer({String id = 'p1', String name = _longName}) {
  return Player(
    id: id,
    name: name,
    number: 99,
    position: 'WS',
    dominantHand: '左',
    grade: '社会人',
    height: 192.5,
    weight: 85,
    standingReach: 245,
    maxReach: 335,
    blockReach: 320,
    spike: 10,
    serve: 9,
    reception: 8,
    dig: 7,
    toss: 6,
    block: 10,
    mobility: 9,
    roles: const ['captain', 'sns', 'contact'],
  );
}

Player _unsetPlayer() {
  return Player(
    id: 'unset',
    name: '',
    number: 0,
    position: '',
    dominantHand: '',
    grade: '',
    height: 0,
    weight: 0,
    standingReach: 0,
    maxReach: 0,
    blockReach: 0,
  );
}

void main() {
  Future<void> pumpDetail(
    WidgetTester tester,
    Player player, {
    Size size = const Size(400, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRepositoryProvider.overrideWithValue(
            FakeCurrentUserRepository()..auth.add('member-1'),
          ),
          playerIssuesProvider.overrideWith(
            (ref, playerId) => Stream.value(const <PlayerIssue>[]),
          ),
        ],
        child: MaterialApp(home: PlayerDetailScreen(player: player)),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in const [
    360.0,
    400.0,
    599.0,
    600.0,
    900.0,
    1200.0,
    1440.0,
  ]) {
    testWidgets('${width.toInt()}px幅で崩れずに表示し、編集・削除へアクセスできる', (tester) async {
      await pumpDetail(tester, _fullPlayer(), size: Size(width, 900));

      expect(find.byType(AbilityRadarChart), findsOneWidget);
      expect(find.byTooltip('編集'), findsOneWidget);
      expect(find.byTooltip('その他の操作'), findsOneWidget);
      expect(find.byTooltip('削除'), findsNothing);
      expect(find.text('選手を削除'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('スカウトカードと改善点の2タブを表示する', (tester) async {
    await pumpDetail(tester, _fullPlayer());

    expect(find.text('スカウトカード'), findsOneWidget);
    expect(find.text('改善点'), findsOneWidget);
    expect(find.text('PLAYER INFORMATION'), findsOneWidget);
  });

  testWidgets('狭い幅でもスクロールして全セクションを表示できる', (tester) async {
    await pumpDetail(tester, _fullPlayer(), size: const Size(360, 740));

    for (final heading in [
      'PHYSICAL DATA',
      'ABILITY RADAR',
      'POSITION SUITABILITY',
      'PLAYER ISSUES',
    ]) {
      await tester.scrollUntilVisible(
        find.text(heading),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(heading), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('基本情報・身体情報・能力値を表示する', (tester) async {
    await pumpDetail(
      tester,
      _fullPlayer(name: '山田 太郎'),
      size: const Size(1440, 1400),
    );

    for (final text in [
      '山田 太郎',
      '99',
      'WS',
      '社会人',
      'キャプテン',
      'SNS係',
      '192.5 cm',
      '85 kg',
      '245 cm',
      '335 cm',
      '320 cm',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    // ジャンプ高は既存の計算(最高到達点 - 指高)のまま。
    expect(find.text('90 cm'), findsOneWidget);
    expect(find.text('90.0 cm'), findsOneWidget);
    // 能力値(1〜10)は従来通り10倍で表示する。
    expect(find.text('100'), findsWidgets);
    expect(find.text('スパイク'), findsOneWidget);
  });

  testWidgets('データ未設定の選手は未設定と表示する', (tester) async {
    await pumpDetail(tester, _unsetPlayer(), size: const Size(1440, 1400));

    expect(find.text('名前未設定'), findsOneWidget);
    expect(find.text('未設定'), findsWidgets);
    expect(find.text('0 cm'), findsNothing);
    expect(find.text('0.0 cm'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('改善点タブへ切り替えられる', (tester) async {
    // 改善点の内容表示は FirebaseAuth を直接参照するため、
    // ID未設定の選手で PlayerIssueSection への切り替えを確認する。
    await pumpDetail(tester, _fullPlayer(id: ''));

    await tester.tap(find.text('改善点'));
    await tester.pumpAndSettle();

    expect(find.text('選手IDがないため、改善点を表示できません。'), findsOneWidget);

    await tester.tap(find.text('スカウトカード'));
    await tester.pumpAndSettle();
    expect(find.byType(AbilityRadarChart), findsOneWidget);
  });

  // 詳細画面は編集・削除を自分で処理する(Phase 2.1)。
  // 以前は 'edit' / 'delete' を返して閉じていたが、現在は
  // 削除は確認ダイアログ、編集は編集画面を開くことをどの幅でも確認する。
  for (final width in const [360.0, 600.0, 1200.0]) {
    testWidgets('${width.toInt()}px幅で削除ボタンは確認ダイアログを開く',
        (tester) async {
      await pumpDetail(tester, _fullPlayer(), size: Size(width, 900));

      await tester.tap(find.byTooltip('その他の操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('選手を削除'));
      await tester.pumpAndSettle();

      expect(find.text('選手を削除しますか？'), findsOneWidget);
      expect(find.byType(PlayerDetailScreen), findsOneWidget);
    });

    testWidgets('${width.toInt()}px幅で編集ボタンは編集画面を開く', (tester) async {
      await pumpDetail(tester, _fullPlayer(), size: Size(width, 900));

      await tester.tap(find.byTooltip('編集'));
      await tester.pumpAndSettle();

      expect(find.text('選手編集'), findsOneWidget);
    });
  }
}
