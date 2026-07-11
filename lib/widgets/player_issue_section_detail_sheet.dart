part of 'player_issue_section.dart';

class _IssueDetailSheet extends ConsumerStatefulWidget {
  const _IssueDetailSheet({
    required this.playerId,
    required this.issue,
    required this.isAdmin,
    required this.currentUid,
    this.onEditIssue,
    this.onDeleteIssue,
  });

  final String playerId;
  final PlayerIssue issue;
  final bool isAdmin;
  final String? currentUid;
  final VoidCallback? onEditIssue;
  final VoidCallback? onDeleteIssue;

  @override
  ConsumerState<_IssueDetailSheet> createState() => _IssueDetailSheetState();
}

class _IssueDetailSheetState extends ConsumerState<_IssueDetailSheet> {
  late final TextEditingController _commentCtrl;
  bool _saving = false;

  bool _canModifyComment(PlayerIssueComment comment) {
    if (widget.isAdmin) return true;
    return widget.currentUid != null && widget.currentUid == comment.createdBy;
  }

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty || _saving) return;

    if (content.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コメントは1000字以内で入力してください。')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(playerIssueRepositoryProvider);
      await repository.addComment(
        playerId: widget.playerId,
        issueId: widget.issue.id,
        content: content,
      );

      _commentCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('コメントの保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteComment(PlayerIssueComment comment) async {
    try {
      final repository = ref.read(playerIssueRepositoryProvider);
      await repository.softDeleteComment(
        playerId: widget.playerId,
        issueId: widget.issue.id,
        commentId: comment.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('コメントの削除に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(
      issueCommentsProvider(
        IssueCommentsArgs(
          playerId: widget.playerId,
          issueId: widget.issue.id,
        ),
      ),
    );

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '改善点の詳細',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (widget.onEditIssue != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: widget.onEditIssue,
                        ),
                      if (widget.onDeleteIssue != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.accent,
                          onPressed: widget.onDeleteIssue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.issue.content),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.issue.createdByName.isEmpty ? '投稿者' : widget.issue.createdByName}・${_formatDate(widget.issue.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 28),
                  const Text(
                    'コメント',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'まだコメントはありません。',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (final comment in comments)
                            _CommentTile(
                              comment: comment,
                              canDelete: _canModifyComment(comment),
                              onDelete: () => _deleteComment(comment),
                            ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _ErrorCard(message: error.toString()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentCtrl,
                    maxLength: 1000,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'コメントを書く',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _addComment,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text('送信'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final PlayerIssueComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(comment.content),
        subtitle: Text(
          '${comment.createdByName.isEmpty ? '投稿者' : comment.createdByName}・${_formatDate(comment.createdAt)}',
        ),
        trailing: canDelete
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.accent,
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}