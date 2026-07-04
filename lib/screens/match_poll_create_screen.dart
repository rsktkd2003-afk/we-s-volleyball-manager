import 'package:flutter/material.dart';

import '../models/match_poll.dart';
import '../repositories/match_poll_repository.dart';

part 'match_poll_create_screen_candidate_input.dart';

class MatchPollCreateScreen extends StatefulWidget {
  const MatchPollCreateScreen({super.key});

  @override
  State<MatchPollCreateScreen> createState() => _MatchPollCreateScreenState();
}

class _MatchPollCreateScreenState extends State<MatchPollCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final List<_CandidateInput> _candidates = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addCandidate();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    for (final candidate in _candidates) {
      candidate.dispose();
    }
    super.dispose();
  }

  void _addCandidate() {
    setState(() {
      _candidates.add(_CandidateInput.initial());
    });
  }

  void _removeCandidate(int index) {
    if (_candidates.length <= 1) return;

    final removed = _candidates.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final note = _noteCtrl.text.trim();

    if (title.isEmpty) {
      _showMessage('タイトルを入力してください。');
      return;
    }

    if (title.length > 50) {
      _showMessage('タイトルは50字以内で入力してください。');
      return;
    }

    if (_candidates.isEmpty) {
      _showMessage('候補日を1件以上追加してください。');
      return;
    }

    final candidates = <MatchPollCandidate>[];

    for (var i = 0; i < _candidates.length; i++) {
      final input = _candidates[i];
      final candidate = input.toCandidate(index: i);

      if (candidate.end.isBefore(candidate.start) ||
          candidate.end.isAtSameMomentAs(candidate.start)) {
        _showMessage('候補${i + 1}の終了時刻は開始時刻より後にしてください。');
        return;
      }

      candidates.add(candidate);
    }

    setState(() => _saving = true);
    try {
      final repository = MatchPollRepository();
      await repository.addPoll(
        title: title,
        note: note,
        candidates: candidates,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('投票の作成に失敗しました: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投票を作成'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'タイトル（必須）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'メモ（任意）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '候補日',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addCandidate,
                icon: const Icon(Icons.add),
                label: const Text('候補を追加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _candidates.length; i++)
            _CandidateInputCard(
              index: i,
              input: _candidates[i],
              canRemove: _candidates.length > 1,
              onChanged: () => setState(() {}),
              onRemove: () => _removeCandidate(i),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('作成'),
          ),
        ],
      ),
    );
  }
}