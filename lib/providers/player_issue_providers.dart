import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_issue.dart';
import '../models/player_issue_comment.dart';
import '../repositories/player_issue_repository.dart';

final playerIssueRepositoryProvider = Provider<PlayerIssueRepository>((ref) {
  return PlayerIssueRepository();
});

final playerIssuesProvider =
    StreamProvider.family<List<PlayerIssue>, String>((ref, playerId) {
  final repository = ref.watch(playerIssueRepositoryProvider);
  return repository.watchIssues(playerId);
});

class IssueCommentsArgs {
  const IssueCommentsArgs({
    required this.playerId,
    required this.issueId,
  });

  final String playerId;
  final String issueId;

  @override
  bool operator ==(Object other) {
    return other is IssueCommentsArgs &&
        other.playerId == playerId &&
        other.issueId == issueId;
  }

  @override
  int get hashCode => Object.hash(playerId, issueId);
}

final issueCommentsProvider =
    StreamProvider.family<List<PlayerIssueComment>, IssueCommentsArgs>(
  (ref, args) {
    final repository = ref.watch(playerIssueRepositoryProvider);

    return repository.watchComments(
      playerId: args.playerId,
      issueId: args.issueId,
    );
  },
);