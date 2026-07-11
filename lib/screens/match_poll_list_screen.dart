import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_poll.dart';
import '../providers/match_poll_providers.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'match_poll_create_screen.dart';
import 'match_poll_detail_screen.dart';

class MatchPollListScreen extends ConsumerStatefulWidget {
  const MatchPollListScreen({super.key});

  @override
  ConsumerState<MatchPollListScreen> createState() =>
      _MatchPollListScreenState();
}

class _MatchPollListScreenState extends ConsumerState<MatchPollListScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final admin = await FirestoreService.isCurrentUserAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pollsAsync = ref.watch(matchPollsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日程調整投票'),
      ),
      body: pollsAsync.when(
        data: (polls) {
          if (polls.isEmpty) {
            return _EmptyPollList(
              onCreate: _openCreateScreen,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '練習試合の候補日を出して、みんなで○△×を投票できます。',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              for (final poll in polls)
                _PollCard(
                  poll: poll,
                  isAdmin: _isAdmin,
                  currentUid: FirebaseAuth.instance.currentUser?.uid,
                  onTap: () => _openDetailScreen(poll),
                  onDelete: () => _softDeletePoll(poll),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('投票一覧を読み込めませんでした: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        icon: const Icon(Icons.add),
        label: const Text('投票を作成'),
      ),
    );
  }

  Future<void> _openCreateScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MatchPollCreateScreen(),
      ),
    );
  }

  Future<void> _openDetailScreen(MatchPoll poll) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchPollDetailScreen(
          pollId: poll.id,
          isAdmin: _isAdmin,
        ),
      ),
    );
  }

  Future<void> _softDeletePoll(MatchPoll poll) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('投票を削除しますか？'),
          content: const Text('投票は一覧から非表示になります。回答データは保持されます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await ref.read(matchPollRepositoryProvider).softDeletePoll(poll.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({
    required this.poll,
    required this.isAdmin,
    required this.currentUid,
    required this.onTap,
    required this.onDelete,
  });

  final MatchPoll poll;
  final bool isAdmin;
  final String? currentUid;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  bool get _canDelete {
    return isAdmin || (currentUid != null && currentUid == poll.createdBy);
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (poll.status) {
      'open' => '受付中',
      'confirmed' => '確定済み',
      _ => poll.status,
    };

    final statusColor = switch (poll.status) {
      'open' => Colors.green,
      'confirmed' => AppColors.accent,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(
          poll.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${poll.candidates.length}候補・$statusLabel',
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(
            Icons.how_to_vote,
            color: Colors.white,
          ),
        ),
        trailing: _canDelete
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.accent,
                onPressed: onDelete,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyPollList extends StatelessWidget {
  const _EmptyPollList({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: InkWell(
          onTap: onCreate,
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.how_to_vote, size: 42),
                SizedBox(height: 12),
                Text(
                  'まだ日程調整投票はありません',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('＋ 投票を作成'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}