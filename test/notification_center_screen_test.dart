import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/announcement.dart';
import 'package:volleyball_app/models/player.dart';
import 'package:volleyball_app/models/player_link_request.dart';
import 'package:volleyball_app/providers/bulletin_providers.dart';
import 'package:volleyball_app/providers/player_link_request_providers.dart';
import 'package:volleyball_app/repositories/player_link_request_repository.dart';
import 'package:volleyball_app/screens/notification_center_screen.dart';

void main() {
  testWidgets('管理者にお知らせと未処理の選手連携申請を表示する', (tester) async {
    final repository = _FakePlayerLinkRequestRepository();
    final request = PlayerLinkRequest(
      id: 'request-1',
      uid: 'member-1',
      playerId: 'player-1',
      playerName: '山田 太郎',
      displayName: 'take',
      createdAt: DateTime(2026, 7, 22, 10, 30),
    );
    final announcement = Announcement(
      id: 'announcement-1',
      title: '今週の練習について',
      body: '開始時刻が変更になりました。',
      sortOrder: 0,
      isPinned: false,
      createdBy: 'admin-1',
      createdAt: DateTime(2026, 7, 22, 9),
      updatedAt: DateTime(2026, 7, 22, 9),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIsAdminProvider.overrideWith((ref) async => true),
          pendingPlayerLinkRequestsProvider.overrideWith(
            (ref) => Stream.value([request]),
          ),
          announcementsProvider.overrideWith(
            (ref) => Stream.value([announcement]),
          ),
          playerLinkRequestRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: NotificationCenterScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('選手連携の申請'), findsOneWidget);
    expect(find.text('山田 太郎'), findsOneWidget);
    expect(find.text('今週の練習について'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '承認'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '承認する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.approvedRequestIds, ['request-1']);
    expect(find.text('連携申請を承認しました'), findsOneWidget);
  });

  testWidgets('一般ユーザーには選手連携申請を表示しない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIsAdminProvider.overrideWith((ref) async => false),
          announcementsProvider.overrideWith(
            (ref) => Stream.value(const <Announcement>[]),
          ),
        ],
        child: const MaterialApp(home: NotificationCenterScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('選手連携の申請'), findsNothing);
    expect(find.text('現在のお知らせはありません。'), findsOneWidget);
  });
}

class _FakePlayerLinkRequestRepository
    implements PlayerLinkRequestRepository {
  final List<String> approvedRequestIds = [];

  @override
  Future<void> approveRequest(String requestId) async {
    approvedRequestIds.add(requestId);
  }

  @override
  Future<void> createRequest({
    required String playerId,
    required String playerName,
  }) async {}

  @override
  Future<List<Player>> loadUnlinkedPlayers() async => const [];

  @override
  Future<PlayerLinkRequest?> loadMyPendingRequest() async => null;

  @override
  Future<void> rejectRequest(String requestId) async {}

  @override
  Future<void> unlinkPlayer({
    required String uid,
    required String playerId,
  }) async {}

  @override
  Stream<List<PlayerLinkRequest>> watchPendingRequests() =>
      const Stream.empty();
}
