import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:volleyball_app/models/announcement.dart';
import 'package:volleyball_app/models/team_goal.dart';
import 'package:volleyball_app/providers/bulletin_providers.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/providers/schedule_providers.dart';
import 'package:volleyball_app/screens/app_shell.dart';
import 'package:volleyball_app/screens/player_edit_screen.dart';
import 'package:volleyball_app/widgets/schedule_goal_note.dart';
import 'package:volleyball_app/widgets/schedule_memo_note.dart';
import 'package:volleyball_app/widgets/bulletin_sticky_area.dart';
import 'support/fake_repositories.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(400, 800),
    const Size(1440, 1000),
  ]) {
    testWidgets('目標とメモが初期画面に見え、カレンダーの前に並ぶ $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final now = DateTime.now();
      final schedules = FakeScheduleReadRepository();
      final players = FakePlayerRepository();
      final user = FakeCurrentUserRepository()..auth.add('member');
      final boundary = GlobalKey();
      if (Platform.environment['CAPTURE_UI'] == '1') {
        await tester.runAsync(() async {
          final font = FontLoader('Roboto')
            ..addFont(
              File(
                'C:/Windows/Fonts/meiryo.ttc',
              ).readAsBytes().then((b) => ByteData.sublistView(b)),
            );
          await font.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(
              File(
                'C:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
              ).readAsBytes().then((b) => ByteData.sublistView(b)),
            );
          await icons.load();
        });
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRepositoryProvider.overrideWithValue(user),
            playerRepositoryProvider.overrideWithValue(players),
            scheduleReadRepositoryProvider.overrideWithValue(schedules),
            announcementsProvider.overrideWith(
              (ref) => Stream.value([
                for (var i = 0; i < 5; i++)
                  Announcement(
                    id: '$i',
                    title: '練習の持ち物と集合時間を確認しましょう $i',
                    body: '体育館シューズを忘れずに',
                    sortOrder: i,
                    isPinned: true,
                    createdBy: 'admin',
                    createdAt: now,
                    updatedAt: now,
                  ),
              ]),
            ),
            goalsForMonthProvider.overrideWith(
              (ref, month) => Stream.value([
                TeamGoal(
                  id: 'goal',
                  monthKey: '${month.year}-${month.month}',
                  title: '声をかけ合って、チームでつなぐ',
                  body: '一人ひとりが声を出し、最後までボールを追いかける。毎回の練習で意識して取り組みましょう。',
                  sortOrder: 0,
                  createdBy: 'admin',
                  createdAt: now,
                  updatedAt: now,
                ),
              ]),
            ),
          ],
          child: RepaintBoundary(
            key: boundary,
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: AppShell(),
          ),
          ),
        ),
      );
      await tester.pump();
      schedules.schedules.add([]);
      schedules.templates.add([]);
      players.last.add([]);
      user.docFor('member').add({'role': 'member'});
      await tester.pumpAndSettle();

      final goal = tester.getRect(find.byType(ScheduleGoalNote));
      final memo = tester.getRect(find.byType(ScheduleMemoNote));
      final calendar = tester.getRect(find.byType(SfCalendar));
      expect(goal.bottom, lessThanOrEqualTo(memo.top));
      final visibleBottom = size.height - (size.width < 600 ? 80 : 0);
      expect(memo.bottom, lessThanOrEqualTo(visibleBottom));
      if (size.width < 900) expect(memo.bottom, lessThan(calendar.top));
      expect(find.text('BULLETIN BOARD'), findsNothing);
      expect(find.text('試合日程投票'), findsNothing);
      expect(find.byTooltip('予定を追加'), findsOneWidget);
      expect(tester.takeException(), isNull);

      if (Platform.environment['CAPTURE_UI'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '../../outputs/schedule-${size.width.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.tap(find.byType(ScheduleMemoNote));
      await tester.pumpAndSettle();
      expect(find.text('チームからのお知らせ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('名前は文字、身体値は小数、背番号と能力値は数値で入力する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PlayerEditScreen(
            player: testPlayer(id: 'p', name: '山田'),
          ),
        ),
      ),
    );
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].keyboardType, TextInputType.text);
    expect(fields[1].keyboardType, TextInputType.number);
    expect(fields[2].keyboardType, TextInputType.text);
    expect(
      fields[5].keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(fields[0].textInputAction, TextInputAction.next);

    await tester.tap(find.byType(TextField).first);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final focused = tester.widgetList<EditableText>(find.byType(EditableText))
        .where((field) => field.focusNode.hasFocus).single;
    expect(focused.controller, fields[1].controller);
  });

  for (final isGoal in [true, false]) {
    testWidgets('詳細表示中の権限変更を反映する: ${isGoal ? '目標' : 'メモ'}', (tester) async {
      final user = FakeCurrentUserRepository()..auth.add('member');
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserRepositoryProvider.overrideWithValue(user),
          announcementsProvider.overrideWith((ref) => Stream.value(const <Announcement>[])),
          goalsForMonthProvider.overrideWith((ref, month) => Stream.value(const <TeamGoal>[])),
        ],
        child: MaterialApp(home: Scaffold(body: isGoal
          ? ScheduleGoalNote(visibleMonth: DateTime(2026, 10))
          : const ScheduleMemoNote())),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(isGoal ? ScheduleGoalNote : ScheduleMemoNote));
      await tester.pumpAndSettle();
      BulletinStickyArea area() => tester.widget<BulletinStickyArea>(find.byType(BulletinStickyArea));
      expect(area().isAdmin, isFalse);
      user.docFor('member').add({'role': 'admin'});
      await tester.pumpAndSettle();
      expect(area().isAdmin, isTrue);
      user.docFor('member').add({'role': 'member'});
      await tester.pumpAndSettle();
      expect(area().isAdmin, isFalse);
      user.docFor('member').add({'role': 'admin'});
      await tester.pumpAndSettle();
      expect(area().isAdmin, isTrue);
      user.docFor('member').addError(StateError('permission-unavailable'));
      await tester.pumpAndSettle();
      expect(area().isAdmin, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
