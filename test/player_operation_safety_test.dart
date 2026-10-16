import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/player.dart';
import 'package:volleyball_app/models/player_issue.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_issue_providers.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/screens/members_screen.dart';
import 'package:volleyball_app/screens/player_detail_screen.dart';
import 'package:volleyball_app/screens/player_edit_screen.dart';

import 'support/fake_repositories.dart';

Player _player({String name = '山田'}) {
  return Player(
    id: 'p1',
    ownerUid: 'owner-1',
    linkedUid: 'linked-1',
    name: name,
    number: 12,
    position: 'MB',
    dominantHand: '右',
    grade: '2年',
    height: 180,
    weight: 70,
    standingReach: 230,
    maxReach: 310,
    blockReach: 300,
    roles: const ['captain'],
  );
}

FirebaseException _firestoreError(String code) {
  return FirebaseException(plugin: 'cloud_firestore', code: code);
}

const _permissionDeleteMessage = '削除する権限がありません。管理者に確認してください。';
const _permissionSaveMessage = '保存する権限がありません。管理者に確認してください。';
const _unavailableMessage = 'サーバーに接続できませんでした。通信環境を確認して、もう一度お試しください。';
const _otherDeleteMessage = '削除に失敗しました。時間をおいて、もう一度お試しください。';
const _otherSaveMessage = '保存に失敗しました。時間をおいて、もう一度お試しください。';

void main() {
  late FakePlayerRepository repository;
  late ValueNotifier<bool> visible;

  setUp(() {
    repository = FakePlayerRepository();
    visible = ValueNotifier<bool>(true);
  });

  tearDown(() => visible.dispose());

  /// 一覧(MembersScreen)から詳細を開いた状態にする。
  /// [visible] を false にすると画面全体を破棄できる(ログアウト相当)。
  Future<void> openDetailFromList(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
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
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, value, _) => value
                ? const Scaffold(body: MembersScreen())
                : const Scaffold(body: Text('ログイン')),
          ),
        ),
      ),
    );
    repository.last.add([_player()]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('山田'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerDetailScreen), findsOneWidget);
  }

  Future<void> tapDelete(WidgetTester tester) async {
    await tester.tap(find.byTooltip('その他の操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('選手を削除'));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDelete(WidgetTester tester) async {
    await tester.tap(find.text('削除する'));
    await tester.pump();
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.byTooltip('編集'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerEditScreen), findsOneWidget);
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  group('選手削除', () {
    testWidgets('削除ボタンで確認ダイアログを表示し、その時点では削除しない',
        (tester) async {
      await openDetailFromList(tester);

      await tapDelete(tester);

      expect(find.text('選手を削除しますか？'), findsOneWidget);
      expect(find.text('「山田」を削除します。この操作は取り消せません。'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除する'), findsOneWidget);
      expect(repository.deletedPlayerIds, isEmpty);
    });

    testWidgets('キャンセル時は削除せず、詳細画面を維持する', (tester) async {
      await openDetailFromList(tester);

      await tapDelete(tester);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('選手を削除しますか？'), findsNothing);
      expect(find.byType(PlayerDetailScreen), findsOneWidget);
      expect(repository.deletedPlayerIds, isEmpty);
    });

    testWidgets('確認後にのみ削除し、成功したら一覧へ戻って完了を通知する', (tester) async {
      await openDetailFromList(tester);

      await tapDelete(tester);
      await confirmDelete(tester);
      await tester.pumpAndSettle();

      expect(repository.deletedPlayerIds, ['p1']);
      expect(find.byType(PlayerDetailScreen), findsNothing);
      expect(find.byType(MembersScreen), findsOneWidget);
      expect(find.text('「山田」を削除しました'), findsOneWidget);
    });

    for (final (label, error, message) in [
      (
        'permission-denied',
        _firestoreError('permission-denied'),
        _permissionDeleteMessage,
      ),
      ('unavailable', _firestoreError('unavailable'), _unavailableMessage),
      ('その他のFirestoreエラー', _firestoreError('internal'),
          _otherDeleteMessage),
      ('Firestore以外の例外', StateError('boom'), _otherDeleteMessage),
    ]) {
      testWidgets('削除失敗($label)時は詳細画面に留まり、エラーを表示する',
          (tester) async {
        await openDetailFromList(tester);
        repository.nextDeleteError = error;

        await tapDelete(tester);
        await confirmDelete(tester);
        await tester.pumpAndSettle();

        expect(find.byType(PlayerDetailScreen), findsOneWidget);
        expect(find.text(message), findsOneWidget);
        expect(find.textContaining('を削除しました'), findsNothing);
        // 内部情報(エラーコードや例外内容)は表示しない。
        expect(
          find.textContaining(
            label == 'Firestore以外の例外' ? 'boom' : 'cloud_firestore',
          ),
          findsNothing,
        );
      });
    }

    testWidgets('削除失敗後に再試行できる', (tester) async {
      await openDetailFromList(tester);
      repository.nextDeleteError = _firestoreError('unavailable');

      await tapDelete(tester);
      await confirmDelete(tester);
      await tester.pumpAndSettle();
      expect(find.byType(PlayerDetailScreen), findsOneWidget);

      await tapDelete(tester);
      await confirmDelete(tester);
      await tester.pumpAndSettle();

      expect(repository.deletedPlayerIds, ['p1', 'p1']);
      expect(find.byType(PlayerDetailScreen), findsNothing);
      expect(find.text('「山田」を削除しました'), findsOneWidget);
    });

    testWidgets('削除処理中は進行状態と説明を表示し、重複操作を受け付けない',
        (tester) async {
      await openDetailFromList(tester);
      repository.deleteGate = Completer<void>();

      await tapDelete(tester);
      await confirmDelete(tester);
      // 処理中のインジケーターが動き続けるため、ダイアログが閉じる時間だけ進める。
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('選手を削除しますか？'), findsNothing);

      expect(
        tester
            .widget<PopupMenuButton<String>>(
              find.byType(PopupMenuButton<String>),
            )
            .enabled,
        isFalse,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is LinearProgressIndicator && w.value == null,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('この画面を離れても処理は続き'), findsOneWidget);

      // 削除・編集ボタンは押せない。
      await tester.tap(find.byTooltip('その他の操作'));
      await tester.tap(find.byTooltip('編集'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('選手を削除しますか？'), findsNothing);
      expect(find.byType(PlayerEditScreen), findsNothing);
      // 結果が出るまでは成功を通知しない。
      expect(find.text('「山田」を削除しました'), findsNothing);

      repository.deleteGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.deletedPlayerIds, ['p1']);
      expect(find.byType(PlayerDetailScreen), findsNothing);
      expect(find.text('「山田」を削除しました'), findsOneWidget);
      expect(find.textContaining('削除処理を続けています'), findsNothing);
    });

    testWidgets('削除中でも画面を離れられ、完了後に結果を通知する', (tester) async {
      await openDetailFromList(tester);
      repository.deleteGate = Completer<void>();

      await tapDelete(tester);
      await confirmDelete(tester);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pageBack();
      // 画面遷移のアニメーションが終わるまで進める(処理中の表示が動き続けるため)。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PlayerDetailScreen), findsNothing);
      expect(find.byType(MembersScreen), findsOneWidget);
      // 結果は未確定なので、成功・失敗は断定しない。
      expect(find.text('削除処理を続けています。完了または失敗したときにお知らせします。'), findsOneWidget);
      expect(find.text('「山田」を削除しました'), findsNothing);

      repository.deleteGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.deletedPlayerIds, ['p1']);
      expect(find.text('「山田」を削除しました'), findsOneWidget);
    });

    testWidgets('削除中に画面を離れた後の失敗も、成功と誤認させずに通知する',
        (tester) async {
      await openDetailFromList(tester);
      repository.deleteGate = Completer<void>();
      repository.nextDeleteError = _firestoreError('permission-denied');

      await tapDelete(tester);
      await confirmDelete(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pageBack();
      // 画面遷移のアニメーションが終わるまで進める(処理中の表示が動き続けるため)。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      repository.deleteGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('「山田」の$_permissionDeleteMessage'), findsOneWidget);
      expect(find.text('「山田」を削除しました'), findsNothing);
      // サーバーが拒否したため、一覧には選手が戻っている。
      expect(find.text('山田'), findsOneWidget);
    });

    testWidgets('削除処理中に画面が破棄されても例外を出さない', (tester) async {
      await openDetailFromList(tester);
      repository.deleteGate = Completer<void>();
      repository.nextDeleteError = _firestoreError('permission-denied');

      await tapDelete(tester);
      await confirmDelete(tester);
      await tester.pump();

      // ログアウト相当: 画面ツリーごと破棄する。
      await tester.pumpWidget(const MaterialApp(home: Text('ログイン')));
      repository.deleteGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('ログイン'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('選手編集', () {
    testWidgets('保存成功時は更新済みの詳細画面に戻る', (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);

      await tester.enterText(field('名前'), '山田 太郎');
      await tester.enterText(field('背番号'), '7');
      await tester.tap(find.byTooltip('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerEditScreen), findsNothing);
      expect(find.byType(PlayerDetailScreen), findsOneWidget);
      // AppBar と PLAYER INFORMATION に更新後の内容を表示する。
      expect(find.text('山田 太郎'), findsWidgets);
      expect(find.text('7'), findsWidgets);
      expect(find.text('選手データを保存しました'), findsOneWidget);

      final saved = repository.updatedPlayers.single;
      expect(saved.id, 'p1');
      final fields = repository.updatedFields.single;
      expect(fields['name'], '山田 太郎');
      expect(fields['number'], 7);
      expect(fields['roles'], ['captain']);
    });

    testWidgets('編集をキャンセルすると元の詳細画面を維持する', (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);

      await tester.enterText(field('名前'), '変更途中');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(PlayerDetailScreen), findsOneWidget);
      expect(find.text('変更途中'), findsNothing);
      expect(find.text('山田'), findsWidgets);
      expect(repository.updatedPlayers, isEmpty);
    });

    for (final (label, error, message) in [
      (
        'permission-denied',
        _firestoreError('permission-denied'),
        _permissionSaveMessage,
      ),
      ('unavailable', _firestoreError('unavailable'), _unavailableMessage),
      ('その他のエラー', _firestoreError('internal'), _otherSaveMessage),
    ]) {
      testWidgets('保存失敗($label)時は編集画面に留まり、入力内容を保持する',
          (tester) async {
        await openDetailFromList(tester);
        await openEditor(tester);
        repository.nextUpdateError = error;

        await tester.enterText(field('名前'), '山田 太郎');
        await tester.tap(find.byTooltip('保存'));
        await tester.pumpAndSettle();

        expect(find.byType(PlayerEditScreen), findsOneWidget);
        expect(find.text(message), findsOneWidget);
        expect(find.text('選手データを保存しました'), findsNothing);
        // 入力内容が残っている。
        expect(find.widgetWithText(TextField, '山田 太郎'), findsOneWidget);
      });
    }

    testWidgets('保存失敗後に再試行でき、成功すると更新済み詳細へ戻る', (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);
      repository.nextUpdateError = _firestoreError('unavailable');

      await tester.enterText(field('名前'), '山田 太郎');
      await tester.tap(find.byTooltip('保存'));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerEditScreen), findsOneWidget);

      await tester.tap(find.byTooltip('保存'));
      await tester.pumpAndSettle();

      expect(repository.updatedPlayers, hasLength(2));
      expect(find.byType(PlayerEditScreen), findsNothing);
      expect(find.text('山田 太郎'), findsWidgets);
    });

    testWidgets('保存中は進行状態と説明を表示し、二重保存を受け付けない',
        (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);
      repository.updateGate = Completer<void>();

      await tester.tap(find.byTooltip('保存'));
      await tester.pump();
      await tester.tap(find.byTooltip('保存'));
      await tester.pump();

      expect(find.text('保存中...', skipOffstage: false), findsOneWidget);
      expect(
        find.textContaining('この画面を離れても処理は続き', skipOffstage: false),
        findsOneWidget,
      );
      expect(repository.updatedPlayers, hasLength(1));
      expect(find.text('選手データを保存しました'), findsNothing);

      repository.updateGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.updatedPlayers, hasLength(1));
      expect(find.byType(PlayerEditScreen), findsNothing);
      expect(find.byType(PlayerDetailScreen), findsOneWidget);
      expect(find.text('選手データを保存しました'), findsOneWidget);
      expect(find.textContaining('保存処理を続けています'), findsNothing);
    });

    testWidgets('保存中でも画面を離れられ、完了後に結果を通知する', (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);
      repository.updateGate = Completer<void>();

      await tester.enterText(field('名前'), '山田 太郎');
      await tester.tap(find.byTooltip('保存'));
      await tester.pump();

      await tester.pageBack();
      // 画面遷移のアニメーションが終わるまで進める(処理中の表示が動き続けるため)。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PlayerEditScreen), findsNothing);
      expect(find.byType(PlayerDetailScreen), findsOneWidget);
      expect(find.text('保存処理を続けています。完了または失敗したときにお知らせします。'), findsOneWidget);
      // 結果は未確定なので、保存済みとは断定しない。
      expect(find.text('選手データを保存しました'), findsNothing);
      expect(find.textContaining('の保存が完了しました'), findsNothing);

      repository.updateGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('「山田 太郎」の保存が完了しました'), findsOneWidget);
      // 詳細画面は最新データ(書き込み後の内容)を表示している。
      expect(find.text('山田 太郎'), findsWidgets);
    });

    testWidgets('保存中に画面を離れた後の失敗も、成功と誤認させずに通知する',
        (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);
      repository.updateGate = Completer<void>();
      repository.nextUpdateError = _firestoreError('unavailable');

      await tester.enterText(field('名前'), '山田 太郎');
      await tester.tap(find.byTooltip('保存'));
      await tester.pump();
      await tester.pageBack();
      // 画面遷移のアニメーションが終わるまで進める(処理中の表示が動き続けるため)。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      repository.updateGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('「山田 太郎」の$_unavailableMessage'), findsOneWidget);
      expect(find.textContaining('の保存が完了しました'), findsNothing);
      // 拒否された変更は元に戻り、詳細画面も元のデータを表示する。
      expect(find.text('山田 太郎'), findsNothing);
      expect(find.text('山田'), findsWidgets);
    });

    testWidgets('保存中に画面が破棄されても例外を出さない', (tester) async {
      for (final error in [null, _firestoreError('permission-denied')]) {
        repository = FakePlayerRepository();
        visible.value = true;
        await openDetailFromList(tester);
        await openEditor(tester);
        repository.updateGate = Completer<void>();
        repository.nextUpdateError = error;

        await tester.tap(find.byTooltip('保存'));
        await tester.pump();

        // ログアウト相当: 画面ツリーごと破棄する。
        await tester.pumpWidget(const MaterialApp(home: Text('ログイン')));
        repository.updateGate!.complete();
        await tester.pumpAndSettle();

        expect(find.text('ログイン'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('部分更新と連携情報', () {
    testWidgets('更新時は編集項目だけを書き込み、ownerUid・linkedUid・対象外の項目は書き込まない', (
      tester,
    ) async {
      await openDetailFromList(tester);
      await openEditor(tester);

      await tester.enterText(field('名前'), '山田 太郎');
      await tester.tap(find.byTooltip('保存'));
      await tester.pumpAndSettle();

      final fields = repository.updatedFields.single;
      expect(fields.keys.toSet(), Player.editableFieldNames.toSet());
      for (final excluded in [
        'linkedUid',
        'ownerUid',
        'id',
        'jump',
        'power',
        'speed',
        'stamina',
        'gameSense',
      ]) {
        expect(fields.containsKey(excluded), isFalse, reason: excluded);
      }
    });

    testWidgets('編集中に連携情報が変わっても、保存で古い値に戻さない', (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);

      // 編集中に、管理者が別ユーザーとの連携を承認した(他端末での変更)。
      final relinked = _player()..linkedUid = 'linked-2';
      repository.last.add([relinked]);
      await tester.pump();

      await tester.enterText(field('名前'), '山田 太郎');
      await tester.tap(find.byTooltip('保存'));
      await tester.pumpAndSettle();

      expect(repository.updatedFields.single.containsKey('linkedUid'), isFalse);

      // 保存後の詳細画面が保持する選手データも、最新の連携情報を持つ。
      await openEditor(tester);
      final opened = tester.widget<PlayerEditScreen>(
        find.byType(PlayerEditScreen),
      );
      expect(opened.player.linkedUid, 'linked-2');
      expect(opened.player.ownerUid, 'owner-1');
      expect(opened.player.name, '山田 太郎');
    });

    testWidgets('更新後の詳細画面は、その後の最新データにも追従する', (tester) async {
      await openDetailFromList(tester);
      await openEditor(tester);

      await tester.enterText(field('名前'), '山田 太郎');
      await tester.tap(find.byTooltip('保存'));
      await tester.pumpAndSettle();
      expect(find.text('山田 太郎'), findsWidgets);

      // 別の端末で学年が変更された。
      final remote = _player(name: '山田 太郎')..grade = '3年';
      repository.last.add([remote]);
      await tester.pumpAndSettle();

      expect(find.text('3年'), findsWidgets);
      expect(find.text('2年'), findsNothing);
    });
  });

  test('toEditableJson は toJson と同じフィールド名・型で編集項目だけを返す', () {
    final player = _player();
    final full = player.toJson();
    final editable = player.toEditableJson();

    expect(editable.keys.toList(), Player.editableFieldNames);
    for (final name in Player.editableFieldNames) {
      expect(editable[name], full[name], reason: name);
      expect(editable[name].runtimeType, full[name].runtimeType, reason: name);
    }
    expect(editable.containsKey('linkedUid'), isFalse);
    expect(editable.containsKey('ownerUid'), isFalse);
  });
}
