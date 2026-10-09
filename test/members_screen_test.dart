import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/screens/members_screen.dart';

import 'support/fake_repositories.dart';

void main() {
  late FakePlayerRepository repository;

  setUp(() {
    repository = FakePlayerRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        playerRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: Scaffold(body: MembersScreen())),
    );
  }

  Future<void> setLargeSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('選手データの受信前は読み込み中を表示する', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('PLAYER SCOUTING BOARD'), findsOneWidget);
  });

  testWidgets('既存の選手一覧を背番号順に表示する', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(buildApp());

    repository.last.add([
      testPlayer(id: 'p2', name: '佐藤', number: 12),
      testPlayer(id: 'p1', name: '山田', number: 3),
    ]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('山田'), findsOneWidget);
    expect(find.text('佐藤'), findsOneWidget);
    expect(find.text('NEW PLAYER'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('#3')).dx,
      lessThan(tester.getTopLeft(find.text('#12')).dx),
    );
  });

  testWidgets('名前検索で一覧を絞り込める', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(buildApp());

    repository.last.add([
      testPlayer(id: 'p1', name: '山田', number: 3),
      testPlayer(id: 'p2', name: '佐藤', number: 12),
    ]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '佐藤');
    await tester.pumpAndSettle();

    expect(find.text('佐藤'), findsWidgets);
    expect(find.text('山田'), findsNothing);
  });

  testWidgets('読み取りエラー時はエラーと再読み込みを表示し、再購読できる', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(buildApp());

    repository.last.addError(StateError('permission-denied'));
    await tester.pumpAndSettle();

    expect(find.textContaining('選手データの取得に失敗しました'), findsOneWidget);
    expect(repository.controllers, hasLength(1));

    await tester.tap(find.text('再読み込み'));
    await tester.pump();

    expect(repository.controllers, hasLength(2));
    repository.last.add([testPlayer(id: 'p1', name: '山田', number: 3)]);
    await tester.pumpAndSettle();

    expect(find.text('山田'), findsOneWidget);
  });

  testWidgets('画面が破棄されると選手データの購読を解除する', (tester) async {
    await setLargeSurface(tester);
    // ログアウト時に main.dart が AppShell(MembersScreen を含む)を
    // LoginScreen に差し替える状況を再現する。
    final signedIn = ValueNotifier<bool>(true);
    addTearDown(signedIn.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: signedIn,
            builder: (context, value, _) => value
                ? const Scaffold(body: MembersScreen())
                : const Scaffold(body: Text('ログイン')),
          ),
        ),
      ),
    );
    repository.last.add([testPlayer(id: 'p1', name: '山田', number: 3)]);
    await tester.pumpAndSettle();
    expect(repository.hasActiveListener, isTrue);

    signedIn.value = false;
    await tester.pumpAndSettle();

    expect(find.text('ログイン'), findsOneWidget);
    expect(repository.hasActiveListener, isFalse);
  });
}
