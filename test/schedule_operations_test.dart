import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/dialogs/schedule_edit_dialog.dart';
import 'package:volleyball_app/models/schedule_response.dart';
import 'package:volleyball_app/models/team_schedule.dart';
import 'package:volleyball_app/providers/schedule_providers.dart';
import 'package:volleyball_app/widgets/schedule_detail_sheet.dart';
import 'package:volleyball_app/widgets/schedule_response_section.dart';

import 'support/fake_repositories.dart';

void main() {
  late FakeScheduleRepository repository;
  final start = DateTime(2026, 10, 16, 19);
  late TeamSchedule schedule;

  setUp(() {
    repository = FakeScheduleRepository();
    schedule = TeamSchedule(
      id: 's1',
      title: '練習',
      location: '体育館',
      start: start,
      end: start.add(const Duration(minutes: 90)),
      durationMinutes: 90,
      color: Colors.blue,
      createdBy: 'user-1',
    );
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump();
  }

  testWidgets('出欠保存・削除を差し替えたRepositoryへ渡す', (tester) async {
    await pump(tester, const ScheduleResponseSection(scheduleId: 's1'));
    await tester.tap(find.text('出欠を保存'));
    await tester.pump();
    expect(repository.savedResponses.single, (
      scheduleId: 's1',
      status: '参加',
      lateTime: '',
    ));
    await tester.tap(find.text('自分の出欠を削除'));
    await tester.pump();
    expect(repository.deletedResponses, ['s1']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('遅刻時間未定の値と表示を維持する', (tester) async {
    await pump(tester, const ScheduleResponseSection(scheduleId: 's1'));
    await tester.tap(find.text('遅刻'));
    await tester.pump();
    await tester.tap(find.text('到着時間は未定'));
    await tester.pump();
    await tester.tap(find.text('出欠を保存'));
    await tester.pump();
    expect(repository.savedResponses.single, (
      scheduleId: 's1',
      status: '遅刻',
      lateTime: '未定',
    ));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('出欠一覧は型付きデータから名前・遅刻時刻を表示する', (tester) async {
    await pump(tester, const ScheduleResponseList(scheduleId: 's1'));
    repository.responseStreams['s1']!.add(const [
      ScheduleResponse(playerName: '山田', status: '参加', lateTime: ''),
      ScheduleResponse(playerName: '佐藤', status: '遅刻', lateTime: '未定'),
    ]);
    await tester.pump();
    expect(find.text('山田'), findsOneWidget);
    expect(find.text('佐藤'), findsOneWidget);
    expect(find.text('遅刻：未定 から参加'), findsOneWidget);
    expect(find.text('1人'), findsNWidgets(2));
    expect(find.text('0人'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(repository.responseStreams['s1']!.hasListener, isFalse);
    await repository.closeResponses();
  });

  testWidgets('予定編集は文字入力と既存の開始時刻・時間を渡す', (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showEditScheduleDialog(context, schedule, repository: repository),
          child: const Text('編集する'),
        ),
      ),
    );
    await tester.tap(find.text('編集する'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, ' 新タイトル ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repository.updatedSchedules.single, {
      'id': 's1',
      'title': ' 新タイトル ',
      'location': '体育館',
      'start': start,
      'durationMinutes': 90,
    });
  });

  testWidgets('予定編集のキャンセルでは書き込まない', (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showEditScheduleDialog(context, schedule, repository: repository),
          child: const Text('編集する'),
        ),
      ),
    );
    await tester.tap(find.text('編集する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(repository.updatedSchedules, isEmpty);
  });

  for (final owner in [true, false]) {
    testWidgets(owner ? 'role取得失敗でも作成者の削除確認は許可する' : 'role取得失敗時に他人の削除を許可しない', (
      tester,
    ) async {
      repository.currentUid = owner ? 'user-1' : 'other';
      repository.adminError = StateError('unavailable');
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pump(
        tester,
        ScheduleDetailSheet(
          schedule: schedule,
          players: const [],
          onEdit: (_) {},
        ),
      );
      repository.responseStreams['s1']!.add([]);
      await tester.pump();
      await tester.tap(find.text('この予定を削除'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (owner) {
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('キャンセル'));
      } else {
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.textContaining('作成者か管理者だけ'), findsOneWidget);
      }
      expect(repository.deletedScheduleIds, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await repository.closeResponses();
    });
  }
}
