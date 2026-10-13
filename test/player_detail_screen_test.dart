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

  for (final width in const [360.0, 400.0, 599.0, 600.0, 900.0, 1200.0, 1440.0]) {
    testWidgets('${width.toInt()}px幅で崩れずに表示し、編集・削除へアクセスできる',
        (tester) async {
      await pumpDetail(tester, _fullPlayer(), size: Size(width, 900));

      expect(find.byType(AbilityRadarChart), findsOneWidget);
      expect(find.byTooltip('編集'), findsOneWidget);
      expect(find.byTooltip('削除'), findsOneWidget);
      // 600px以上は文字ラベル付き。
      expect(find.text('編集'), width >= 600 ? findsOneWidget : findsNothing);
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
    await pumpDetail(tester, _fullPlayer(name: '山田 太郎'), size: const Size(1440, 1400));

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

  for (final (action, width) in const [
    ('edit', 400.0),
    ('delete', 400.0),
    ('edit', 1200.0),
    ('delete', 1200.0),
  ]) {
    testWidgets('${width.toInt()}px幅の$actionボタンは従来通りの結果を返す',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRepositoryProvider.overrideWithValue(
              FakeCurrentUserRepository()..auth.add('member-1'),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerDetailScreen(player: _fullPlayer()),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(action == 'edit' ? '編集' : '削除'));
      await tester.pumpAndSettle();

      expect(result, action);
      expect(find.byType(PlayerDetailScreen), findsNothing);
    });
  }
}
