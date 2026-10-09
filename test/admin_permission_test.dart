import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/announcement.dart';
import 'package:volleyball_app/models/player.dart';
import 'package:volleyball_app/models/player_link_request.dart';
import 'package:volleyball_app/providers/bulletin_providers.dart';
import 'package:volleyball_app/providers/current_user_providers.dart';
import 'package:volleyball_app/providers/player_link_request_providers.dart';
import 'package:volleyball_app/providers/player_providers.dart';
import 'package:volleyball_app/repositories/player_link_request_repository.dart';
import 'package:volleyball_app/screens/home_screen.dart';
import 'package:volleyball_app/screens/notification_center_screen.dart';

import 'support/fake_repositories.dart';

bool _treatedAsAdmin(AsyncValue<bool> value) {
  return value.maybeWhen(data: (v) => v, orElse: () => false);
}

void main() {
  group('currentUserIsAdminProvider', () {
    late FakeCurrentUserRepository repository;
    late ProviderContainer container;
    late List<AsyncValue<bool>> history;
    late ProviderSubscription<AsyncValue<bool>> sub;

    Future<void> settle() async {
      for (var i = 0; i < 3; i++) {
        await container.pump();
        await Future<void>.delayed(Duration.zero);
      }
    }

    Future<void> signIn(String uid, Map<String, dynamic>? doc) async {
      repository.auth.add(uid);
      await settle();
      repository.docFor(uid).add(doc);
      await settle();
    }

    setUp(() {
      repository = FakeCurrentUserRepository();
      container = ProviderContainer(
        overrides: [currentUserRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      history = [];
      sub = container.listen(
        currentUserIsAdminProvider,
        (_, next) => history.add(next),
        fireImmediately: true,
      );
    });

    AsyncValue<bool> current() => sub.read();

    test('認証状態が未確定の間は管理者として扱わない', () async {
      await settle();

      expect(current().isLoading, isTrue);
      expect(_treatedAsAdmin(current()), isFalse);
    });

    test('admin → logout → member で管理者判定が残らない', () async {
      await signIn('admin-1', {'role': 'admin'});
      expect(current().value, isTrue);

      repository.auth.add(null);
      await settle();
      expect(current().value, isFalse);

      history.clear();
      repository.auth.add('member-1');
      await settle();
      // member のドキュメント受信前も管理者として扱わない。
      expect(_treatedAsAdmin(current()), isFalse);

      repository.docFor('member-1').add({'role': 'member', 'playerId': 'p1'});
      await settle();

      expect(current().value, isFalse);
      expect(history.where(_treatedAsAdmin), isEmpty);
    });

    test('ログアウトを挟まない別ユーザーへの切り替えでも以前の判定を引き継がない',
        () async {
      await signIn('admin-1', {'role': 'admin'});
      expect(current().value, isTrue);

      history.clear();
      repository.auth.add('member-1');
      await settle();

      expect(_treatedAsAdmin(current()), isFalse);
      expect(history.where(_treatedAsAdmin), isEmpty);
      expect(repository.hasActiveDocListener('admin-1'), isFalse);
    });

    test('member → logout → admin で管理者に切り替わる', () async {
      await signIn('member-1', {'role': 'member', 'playerId': 'p1'});
      expect(current().value, isFalse);

      repository.auth.add(null);
      await settle();
      expect(current().value, isFalse);

      await signIn('admin-1', {'role': 'admin'});
      expect(current().value, isTrue);
    });

    test('users/{uid}.role の変更をリアルタイムに反映する', () async {
      await signIn('u1', {'role': 'member'});
      expect(current().value, isFalse);

      repository.docFor('u1').add({'role': 'admin'});
      await settle();
      expect(current().value, isTrue);

      repository.docFor('u1').add({'role': 'member'});
      await settle();
      expect(current().value, isFalse);
    });

    test('roleが未設定・想定外の値なら管理者として扱わない', () async {
      await signIn('u1', {'email': 'a@example.com'});
      expect(current().value, isFalse);

      repository.docFor('u1').add({'role': 'Admin'});
      await settle();
      expect(current().value, isFalse);
    });

    test('ユーザードキュメントが存在しない場合は管理者として扱わない', () async {
      await signIn('u1', null);

      expect(current().value, isFalse);
    });

    test('認証状態の取得エラー時は管理者として扱わない', () async {
      repository.auth.addError(StateError('auth-failed'));
      await settle();

      expect(current().hasError, isTrue);
      expect(_treatedAsAdmin(current()), isFalse);
    });

    test('読み込み中に待った .future は、確定後の権限で解決する', () async {
      final future = container.read(currentUserIsAdminProvider.future);

      await signIn('admin-1', {'role': 'admin'});

      expect(await future.timeout(const Duration(seconds: 1)), isTrue);
    });

    test('読み込み中に待った .future は、member なら false で解決する', () async {
      final future = container.read(currentUserIsAdminProvider.future);

      await signIn('member-1', {'role': 'member'});

      expect(await future.timeout(const Duration(seconds: 1)), isFalse);
    });

    test('ユーザードキュメント取得エラー時は管理者として扱わない', () async {
      await signIn('u1', {'role': 'admin'});
      expect(current().value, isTrue);

      repository.docFor('u1').addError(StateError('permission-denied'));
      await settle();

      expect(current().hasError, isTrue);
      expect(_treatedAsAdmin(current()), isFalse);
    });
  });

  group('画面の管理者判定', () {
    final request = PlayerLinkRequest(
      id: 'request-1',
      uid: 'member-9',
      playerId: 'player-1',
      playerName: '山田 太郎',
      displayName: 'take',
      createdAt: DateTime(2026, 7, 22, 10, 30),
    );

    testWidgets('admin → logout → member で HomeScreen に管理者用の件数が残らない',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final userRepository = FakeCurrentUserRepository();
      final playerRepository = FakePlayerRepository();
      final signedIn = ValueNotifier<bool>(true);
      addTearDown(signedIn.dispose);
      var pendingSubscriptions = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRepositoryProvider.overrideWithValue(userRepository),
            playerRepositoryProvider.overrideWithValue(playerRepository),
            pendingPlayerLinkRequestsProvider.overrideWith((ref) {
              pendingSubscriptions++;
              return Stream.value([request]);
            }),
          ],
          child: MaterialApp(
            home: ValueListenableBuilder<bool>(
              valueListenable: signedIn,
              builder: (context, value, _) => value
                  ? const HomeScreen()
                  : const Scaffold(body: Text('ログイン')),
            ),
          ),
        ),
      );

      userRepository.auth.add('admin-1');
      await tester.pump();
      await tester.pump();
      userRepository.docFor('admin-1').add({'role': 'admin'});
      playerRepository.last.add(<Player>[]);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(pendingSubscriptions, 1);

      // ログアウト: main.dart と同様に HomeScreen を破棄する。
      userRepository.auth.add(null);
      signedIn.value = false;
      await tester.pumpAndSettle();

      // 別ユーザー(member)でログイン。
      userRepository.auth.add('member-1');
      signedIn.value = true;
      await tester.pump();
      await tester.pump();
      expect(find.text('1'), findsNothing);

      userRepository.docFor('member-1').add({'role': 'member', 'playerId': 'p1'});
      playerRepository.last.add(<Player>[]);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsNothing);
      expect(pendingSubscriptions, 1);
    });

    testWidgets('承認の確認中に権限が外れた場合は連携申請を処理しない', (tester) async {
      final userRepository = FakeCurrentUserRepository();
      final linkRepository = _RecordingLinkRequestRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRepositoryProvider.overrideWithValue(userRepository),
            playerLinkRequestRepositoryProvider.overrideWithValue(linkRepository),
            pendingPlayerLinkRequestsProvider.overrideWith(
              (ref) => Stream.value([request]),
            ),
            announcementsProvider.overrideWith(
              (ref) => Stream.value(const <Announcement>[]),
            ),
          ],
          child: const MaterialApp(home: NotificationCenterScreen()),
        ),
      );

      userRepository.auth.add('admin-1');
      await tester.pump();
      await tester.pump();
      userRepository.docFor('admin-1').add({'role': 'admin'});
      await tester.pumpAndSettle();
      expect(find.text('選手連携の申請'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '承認'));
      await tester.pumpAndSettle();

      // 確認ダイアログ表示中に role が member へ変更される。
      userRepository.docFor('admin-1').add({'role': 'member'});
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '承認する'));
      await tester.pumpAndSettle();

      expect(linkRepository.approvedRequestIds, isEmpty);
      expect(
        find.text('管理者権限を確認できないため、連携申請を処理できません'),
        findsOneWidget,
      );
      expect(find.text('選手連携の申請'), findsNothing);
    });

    testWidgets('一般メンバーには連携申請を表示せず、購読もしない', (tester) async {
      final userRepository = FakeCurrentUserRepository();
      var pendingSubscriptions = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRepositoryProvider.overrideWithValue(userRepository),
            pendingPlayerLinkRequestsProvider.overrideWith((ref) {
              pendingSubscriptions++;
              return Stream.value([request]);
            }),
            announcementsProvider.overrideWith(
              (ref) => Stream.value(const <Announcement>[]),
            ),
          ],
          child: const MaterialApp(home: NotificationCenterScreen()),
        ),
      );

      userRepository.auth.add('member-1');
      await tester.pump();
      await tester.pump();
      userRepository.docFor('member-1').add({'role': 'member'});
      await tester.pumpAndSettle();

      expect(find.text('選手連携の申請'), findsNothing);
      expect(find.text('現在のお知らせはありません。'), findsOneWidget);
      expect(pendingSubscriptions, 0);
    });
  });
}

class _RecordingLinkRequestRepository implements PlayerLinkRequestRepository {
  final List<String> approvedRequestIds = [];
  final List<String> rejectedRequestIds = [];

  @override
  Future<void> approveRequest(String requestId) async {
    approvedRequestIds.add(requestId);
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    rejectedRequestIds.add(requestId);
  }

  @override
  Future<void> createRequest({
    required String playerId,
    required String playerName,
  }) async {}

  @override
  Future<PlayerLinkRequest?> loadMyPendingRequest() async => null;

  @override
  Future<List<Player>> loadUnlinkedPlayers() async => const [];

  @override
  Future<void> unlinkPlayer({
    required String uid,
    required String playerId,
  }) async {}

  @override
  Stream<List<PlayerLinkRequest>> watchPendingRequests() =>
      const Stream.empty();
}
