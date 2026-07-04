import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_poll.dart';
import '../models/match_poll_vote.dart';
import '../providers/match_poll_providers.dart';

part 'match_poll_detail_screen_widgets.dart';

class MatchPollDetailScreen extends ConsumerStatefulWidget {
  const MatchPollDetailScreen({
    super.key,
    required this.pollId,
    required this.isAdmin,
  });

  final String pollId;
  final bool isAdmin;

  @override
  ConsumerState<MatchPollDetailScreen> createState() =>
      _MatchPollDetailScreenState();
}

class _MatchPollDetailScreenState extends ConsumerState<MatchPollDetailScreen> {
  final Map<String, String> _choices = {};
  final Map<String, TextEditingController> _commentCtrls = {};
  bool _initialized = false;
  bool _saving = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    for (final controller in _commentCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeMyVote({
    required MatchPoll poll,
    required List<MatchPollVote> votes,
  }) {
    if (_initialized) return;

    final uid = _uid;
    final myVote = uid == null
        ? null
        : votes.where((vote) => vote.uid == uid).firstOrNull;

    for (final candidate in poll.candidates) {
      final answer = myVote?.answers[candidate.id];
      _choices[candidate.id] = answer?.choice ?? 'ng';
      _commentCtrls[candidate.id] = TextEditingController(
        text: answer?.comment ?? '',
      );
    }

    _initialized = true;
  }

  Future<void> _saveVote(MatchPoll poll) async {
    if (!poll.isOpen || _saving) return;

    final answers = <String, MatchPollAnswer>{};

    for (final candidate in poll.candidates) {
      final choice = _choices[candidate.id] ?? 'ng';
      final comment = _commentCtrls[candidate.id]?.text.trim() ?? '';

      if (choice == 'maybe' && comment.length > 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('△のコメントは200字以内で入力してください。')),
        );
        return;
      }

      answers[candidate.id] = MatchPollAnswer(
        choice: choice,
        comment: choice == 'maybe' ? comment : '',
      );
    }

    setState(() => _saving = true);
    try {
      await ref.read(matchPollRepositoryProvider).saveMyVote(
            pollId: poll.id,
            answers: answers,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回答を保存しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('回答の保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmPoll({
    required MatchPoll poll,
    required MatchPollCandidate candidate,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('この日程で確定しますか？'),
          content: Text(
            '${_formatDateTime(candidate.start)} 〜 ${_formatTime(candidate.end)}\n'
            '予定表にも追加されます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('確定'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await ref.read(matchPollRepositoryProvider).confirmPoll(
            poll: poll,
            candidate: candidate,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日程を確定し、予定表に追加しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('確定に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pollAsync = ref.watch(matchPollProvider(widget.pollId));
    final votesAsync = ref.watch(matchPollVotesProvider(widget.pollId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('投票詳細'),
      ),
      body: pollAsync.when(
        data: (poll) {
          if (poll == null || poll.isDeleted) {
            return const Center(child: Text('投票が見つかりません。'));
          }

          return votesAsync.when(
            data: (votes) {
              _initializeMyVote(poll: poll, votes: votes);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PollHeader(poll: poll),
                  const SizedBox(height: 16),
                  for (final candidate in poll.candidates)
                    _CandidateVoteCard(
                      poll: poll,
                      candidate: candidate,
                      votes: votes,
                      isAdmin: widget.isAdmin,
                      choice: _choices[candidate.id] ?? 'ng',
                      commentCtrl: _commentCtrls[candidate.id]!,
                      onChoiceChanged: poll.isOpen
                          ? (value) {
                              setState(() {
                                _choices[candidate.id] = value;
                              });
                            }
                          : null,
                      onConfirm: poll.isOpen && widget.isAdmin
                          ? () => _confirmPoll(
                                poll: poll,
                                candidate: candidate,
                              )
                          : null,
                    ),
                  const SizedBox(height: 12),
                  if (poll.isOpen)
                    ElevatedButton.icon(
                      onPressed: _saving ? null : () => _saveVote(poll),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('回答を保存'),
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('この投票は確定済みのため、回答は変更できません。'),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('回答を読み込めませんでした: $error'),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('投票を読み込めませんでした: $error'),
          ),
        ),
      ),
    );
  }
}