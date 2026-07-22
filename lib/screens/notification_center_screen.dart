import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement.dart';
import '../models/player_link_request.dart';
import '../providers/bulletin_providers.dart';
import '../providers/player_link_request_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/pinned_paper_card.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  final Set<String> processingRequestIds = <String>{};

  Future<void> refresh() async {
    ref.invalidate(currentUserIsAdminProvider);
    ref.invalidate(announcementsProvider);
    ref.invalidate(pendingPlayerLinkRequestsProvider);

    await Future.wait([
      ref.read(currentUserIsAdminProvider.future),
      ref.read(announcementsProvider.future),
    ]);
  }

  Future<void> processRequest(
    PlayerLinkRequest request, {
    required bool approve,
  }) async {
    final action = approve ? '承認' : '却下';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('連携申請を$action'),
          content: Text(
            '${request.displayName} さんの「${request.playerName}」への連携申請を$actionしますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: approve
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
              child: Text('$actionする'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => processingRequestIds.add(request.id));

    try {
      final repository = ref.read(playerLinkRequestRepositoryProvider);
      if (approve) {
        await repository.approveRequest(request.id);
      } else {
        await repository.rejectRequest(request.id);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('連携申請を$actionしました')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('連携申請の$actionに失敗しました: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => processingRequestIds.remove(request.id));
      }
    }
  }

  void showAnnouncement(Announcement announcement) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          title: Text(announcement.title),
          content: SingleChildScrollView(
            child: Text(
              announcement.body.trim().isEmpty
                  ? '本文はありません。'
                  : announcement.body,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(currentUserIsAdminProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('対応・通知'),
      ),
      body: CorkBoardBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                adminAsync.when(
                  data: (isAdmin) {
                    if (!isAdmin) return const SizedBox.shrink();
                    return _buildPendingRequests();
                  },
                  loading: () => const PinnedPaperCard(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _ErrorPaper(
                    title: '権限情報を読み込めませんでした',
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(currentUserIsAdminProvider),
                  ),
                ),
                const SizedBox(height: 12),
                PinnedPaperCard(
                  showTape: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(
                        icon: Icons.campaign_outlined,
                        title: 'チームからのお知らせ',
                      ),
                      const SizedBox(height: 12),
                      announcementsAsync.when(
                        data: _buildAnnouncements,
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => _InlineError(
                          message: error.toString(),
                          onRetry: () => ref.invalidate(announcementsProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    final requestsAsync = ref.watch(pendingPlayerLinkRequestsProvider);

    return PinnedPaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.how_to_reg_outlined,
            title: '選手連携の申請',
          ),
          const SizedBox(height: 12),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const _EmptyMessage(
                  icon: Icons.check_circle_outline,
                  message: '未処理の申請はありません。',
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < requests.length; index++) ...[
                    _PlayerLinkRequestCard(
                      request: requests[index],
                      processing:
                          processingRequestIds.contains(requests[index].id),
                      onApprove: () => processRequest(
                        requests[index],
                        approve: true,
                      ),
                      onReject: () => processRequest(
                        requests[index],
                        approve: false,
                      ),
                    ),
                    if (index < requests.length - 1) const Divider(height: 24),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _InlineError(
              message: error.toString(),
              onRetry: () =>
                  ref.invalidate(pendingPlayerLinkRequestsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncements(List<Announcement> announcements) {
    if (announcements.isEmpty) {
      return const _EmptyMessage(
        icon: Icons.notifications_none,
        message: '現在のお知らせはありません。',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < announcements.length; index++) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              announcements[index].isPinned
                  ? Icons.push_pin
                  : Icons.notifications_outlined,
              color: announcements[index].isPinned
                  ? AppColors.accent
                  : AppColors.textSecondary,
            ),
            title: Text(
              announcements[index].title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              announcements[index].body.trim().isEmpty
                  ? _formatDate(announcements[index].createdAt)
                  : '${announcements[index].body}\n${_formatDate(announcements[index].createdAt)}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAnnouncement(announcements[index]),
          ),
          if (index < announcements.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerLinkRequestCard extends StatelessWidget {
  const _PlayerLinkRequestCard({
    required this.request,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  final PlayerLinkRequest request;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.playerName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text('申請者: ${request.displayName}'),
        if (request.createdAt != null) ...[
          const SizedBox(height: 2),
          Text(
            '申請日時: ${_formatDate(request.createdAt!)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: processing ? null : onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
                child: const Text('却下'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: processing ? null : onApprove,
                child: processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('承認'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '読み込みに失敗しました: $message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('再読み込み'),
        ),
      ],
    );
  }
}

class _ErrorPaper extends StatelessWidget {
  const _ErrorPaper({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PinnedPaperCard(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}/$month/$day $hour:$minute';
}
