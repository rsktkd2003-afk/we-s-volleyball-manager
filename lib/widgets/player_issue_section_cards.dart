part of 'player_issue_section.dart';

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.canModify,
    required this.onTap,
    required this.onDelete,
  });

  final PlayerIssue issue;
  final bool canModify;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(
          issue.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${issue.createdByName.isEmpty ? '投稿者' : issue.createdByName}・${_formatDate(issue.createdAt)}',
        ),
        trailing: canModify
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFD32F2F),
                onPressed: onDelete,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyIssueCard extends StatelessWidget {
  const _EmptyIssueCard({
    required this.canAdd,
    required this.onAdd,
  });

  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: canAdd ? onAdd : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            canAdd ? '＋ 改善点を追加' : 'まだ改善点はありません。',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFD6D6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('読み込みに失敗しました: $message'),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}