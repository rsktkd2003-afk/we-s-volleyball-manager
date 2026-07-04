part of 'match_poll_detail_screen.dart';

class _PollHeader extends StatelessWidget {
  const _PollHeader({
    required this.poll,
  });

  final MatchPoll poll;

  @override
  Widget build(BuildContext context) {
    final statusLabel = poll.status == 'open' ? '受付中' : '確定済み';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (poll.note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(poll.note),
            ],
            const SizedBox(height: 8),
            Text(
              '状態: $statusLabel',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateVoteCard extends StatelessWidget {
  const _CandidateVoteCard({
    required this.poll,
    required this.candidate,
    required this.votes,
    required this.isAdmin,
    required this.choice,
    required this.commentCtrl,
    required this.onChoiceChanged,
    required this.onConfirm,
  });

  final MatchPoll poll;
  final MatchPollCandidate candidate;
  final List<MatchPollVote> votes;
  final bool isAdmin;
  final String choice;
  final TextEditingController commentCtrl;
  final ValueChanged<String>? onChoiceChanged;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final summary = _summaryFor(candidate.id, votes);
    final maybeSelected = choice == 'maybe';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDateTime(candidate.start)} 〜 ${_formatTime(candidate.end)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              candidate.location.trim().isEmpty
                  ? '場所: 未定'
                  : '場所: ${candidate.location}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _CountChip(label: '○', count: summary.ok),
                _CountChip(label: '△', count: summary.maybe),
                _CountChip(label: '×', count: summary.ng),
              ],
            ),
            if (summary.comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...summary.comments.map(
                (text) => Text(
                  '・$text',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
            const Text('自分の回答'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ok', label: Text('○')),
                ButtonSegment(value: 'maybe', label: Text('△')),
                ButtonSegment(value: 'ng', label: Text('×')),
              ],
              selected: {choice},
              onSelectionChanged: onChoiceChanged == null
                  ? null
                  : (selected) => onChoiceChanged!(selected.first),
            ),
            if (maybeSelected) ...[
              const SizedBox(height: 8),
              TextField(
                controller: commentCtrl,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '△の理由・条件',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (onConfirm != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.event_available),
                  label: const Text('この日程で確定'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label $count'),
    );
  }
}

class _VoteSummary {
  const _VoteSummary({
    required this.ok,
    required this.maybe,
    required this.ng,
    required this.comments,
  });

  final int ok;
  final int maybe;
  final int ng;
  final List<String> comments;
}

_VoteSummary _summaryFor(String candidateId, List<MatchPollVote> votes) {
  var ok = 0;
  var maybe = 0;
  var ng = 0;
  final comments = <String>[];

  for (final vote in votes) {
    final answer = vote.answers[candidateId];
    if (answer == null) continue;

    switch (answer.choice) {
      case 'ok':
        ok++;
        break;
      case 'maybe':
        maybe++;
        if (answer.comment.trim().isNotEmpty) {
          comments.add('${vote.displayName}: ${answer.comment}');
        }
        break;
      case 'ng':
        ng++;
        break;
    }
  }

  return _VoteSummary(
    ok: ok,
    maybe: maybe,
    ng: ng,
    comments: comments,
  );
}

String _formatDateTime(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${_formatTime(date)}';
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}