import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../models/player_issue.dart';
import '../models/player_issue_comment.dart';
import '../providers/player_issue_providers.dart';
import '../services/firestore_service.dart';

part 'player_issue_section_cards.dart';
part 'player_issue_section_detail_sheet.dart';

class PlayerIssueSection extends ConsumerStatefulWidget {
  const PlayerIssueSection({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  ConsumerState<PlayerIssueSection> createState() => _PlayerIssueSectionState();
}

class _PlayerIssueSectionState extends ConsumerState<PlayerIssueSection> {
  bool _isAdmin = false;
  bool _loadingRole = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get _isLinkedPlayer {
    final uid = _uid;
    if (uid == null) return false;
    return widget.player.linkedUid == uid;
  }

  bool get _canAddIssue => _isAdmin || _isLinkedPlayer;

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
      _loadingRole = false;
    });
  }

  bool _canModify(String createdBy) {
    if (_isAdmin) return true;
    final uid = _uid;
    return uid != null && uid == createdBy;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.player.id.trim().isEmpty) {
      return const Center(
        child: Text('選手IDがないため、改善点を表示できません。'),
      );
    }

    final issuesAsync = ref.watch(playerIssuesProvider(widget.player.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '改善点',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!_loadingRole && _canAddIssue)
              ElevatedButton.icon(
                onPressed: _showAddIssueDialog,
                icon: const Icon(Icons.add),
                label: const Text('追加'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '選手本人または管理者が課題を追加できます。コメントは全員が書けます。',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 16),
        issuesAsync.when(
          data: (issues) {
            if (issues.isEmpty) {
              return _EmptyIssueCard(
                canAdd: !_loadingRole && _canAddIssue,
                onAdd: _showAddIssueDialog,
              );
            }

            return Column(
              children: [
                for (final issue in issues)
                  _IssueCard(
                    issue: issue,
                    canModify: _canModify(issue.createdBy),
                    onTap: () => _showIssueDetail(issue),
                    onDelete: () => _confirmDeleteIssue(issue),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _ErrorCard(message: error.toString()),
        ),
      ],
    );
  }

  Future<void> _showAddIssueDialog() async {
    await _showIssueInputDialog(
      title: '改善点を追加',
      initialContent: '',
      onSubmit: (content) async {
        final repository = ref.read(playerIssueRepositoryProvider);
        await repository.addIssue(
          playerId: widget.player.id,
          content: content,
        );
      },
    );
  }

  Future<void> _showEditIssueDialog(PlayerIssue issue) async {
    await _showIssueInputDialog(
      title: '改善点を編集',
      initialContent: issue.content,
      onSubmit: (content) async {
        final repository = ref.read(playerIssueRepositoryProvider);
        await repository.updateIssue(
          playerId: widget.player.id,
          issueId: issue.id,
          content: content,
        );
      },
    );
  }

  Future<void> _showIssueInputDialog({
    required String title,
    required String initialContent,
    required Future<void> Function(String content) onSubmit,
  }) async {
    final controller = TextEditingController(text: initialContent);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final content = controller.text.trim();
              if (content.isEmpty || saving) return;

              if (content.length > 2000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('改善点は2000字以内で入力してください。')),
                );
                return;
              }

              setDialogState(() => saving = true);
              try {
                await onSubmit(content);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                setDialogState(() => saving = false);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('保存に失敗しました: $e')),
                );
              }
            }

            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                maxLength: 2000,
                maxLines: 6,
                minLines: 3,
                decoration: const InputDecoration(
                  labelText: '内容',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _confirmDeleteIssue(PlayerIssue issue) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('削除しますか？'),
          content: const Text('この改善点を削除します。コメントも画面上では見えなくなります。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F),
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      final repository = ref.read(playerIssueRepositoryProvider);
      await repository.softDeleteIssue(
        playerId: widget.player.id,
        issueId: issue.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  Future<void> _showIssueDetail(PlayerIssue issue) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _IssueDetailSheet(
          playerId: widget.player.id,
          issue: issue,
          isAdmin: _isAdmin,
          currentUid: _uid,
          onEditIssue: _canModify(issue.createdBy)
              ? () {
                  Navigator.of(sheetContext).pop();
                  _showEditIssueDialog(issue);
                }
              : null,
          onDeleteIssue: _canModify(issue.createdBy)
              ? () {
                  Navigator.of(sheetContext).pop();
                  _confirmDeleteIssue(issue);
                }
              : null,
        );
      },
    );
  }
}