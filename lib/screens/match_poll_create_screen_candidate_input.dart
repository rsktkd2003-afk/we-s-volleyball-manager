part of 'match_poll_create_screen.dart';

class _CandidateInputCard extends StatelessWidget {
  const _CandidateInputCard({
    required this.index,
    required this.input,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _CandidateInput input;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '候補${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: input.date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );

                      if (picked == null) return;
                      input.date = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      );
                      onChanged();
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_formatDate(input.date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: input.startTime,
                      );

                      if (picked == null) return;
                      input.startTime = picked;
                      onChanged();
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text('開始 ${input.startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: input.endTime,
                      );

                      if (picked == null) return;
                      input.endTime = picked;
                      onChanged();
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text('終了 ${input.endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: input.locationCtrl,
              decoration: const InputDecoration(
                labelText: '場所（任意）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateInput {
  _CandidateInput({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.locationCtrl,
  });

  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  final TextEditingController locationCtrl;

  factory _CandidateInput.initial() {
    final now = DateTime.now();
    return _CandidateInput(
      date: DateTime(now.year, now.month, now.day),
      startTime: const TimeOfDay(hour: 19, minute: 0),
      endTime: const TimeOfDay(hour: 21, minute: 0),
      locationCtrl: TextEditingController(),
    );
  }

  MatchPollCandidate toCandidate({required int index}) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final end = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    return MatchPollCandidate(
      id: 'candidate_$index',
      start: start,
      end: end,
      location: locationCtrl.text.trim(),
    );
  }

  void dispose() {
    locationCtrl.dispose();
  }
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}