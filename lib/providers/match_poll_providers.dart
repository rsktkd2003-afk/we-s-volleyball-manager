import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_poll.dart';
import '../models/match_poll_vote.dart';
import '../repositories/match_poll_repository.dart';

final matchPollRepositoryProvider = Provider<MatchPollRepository>((ref) {
  return MatchPollRepository();
});

final matchPollsProvider = StreamProvider<List<MatchPoll>>((ref) {
  final repository = ref.watch(matchPollRepositoryProvider);
  return repository.watchPolls();
});

final matchPollProvider =
    StreamProvider.family<MatchPoll?, String>((ref, pollId) {
  final repository = ref.watch(matchPollRepositoryProvider);
  return repository.watchPoll(pollId);
});

final matchPollVotesProvider =
    StreamProvider.family<List<MatchPollVote>, String>((ref, pollId) {
  final repository = ref.watch(matchPollRepositoryProvider);
  return repository.watchVotes(pollId);
});