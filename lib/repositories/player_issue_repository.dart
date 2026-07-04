import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/player_issue.dart';
import '../models/player_issue_comment.dart';

class PlayerIssueRepository {
  PlayerIssueRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _issues(String playerId) {
    return _firestore
        .collection('players')
        .doc(playerId)
        .collection('issues');
  }

  CollectionReference<Map<String, dynamic>> _comments({
    required String playerId,
    required String issueId,
  }) {
    return _issues(playerId).doc(issueId).collection('comments');
  }

  Stream<List<PlayerIssue>> watchIssues(String playerId) {
    return _issues(playerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(PlayerIssue.fromFirestore)
          .where((issue) => !issue.isDeleted)
          .toList();
    });
  }

  Stream<List<PlayerIssueComment>> watchComments({
    required String playerId,
    required String issueId,
  }) {
    return _comments(playerId: playerId, issueId: issueId)
        .orderBy('createdAt')
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(PlayerIssueComment.fromFirestore)
          .where((comment) => !comment.isDeleted)
          .toList();
    });
  }

  Future<void> addIssue({
    required String playerId,
    required String content,
  }) async {
    final user = _requireUser();
    final now = DateTime.now();

    final issue = PlayerIssue(
      id: '',
      playerId: playerId,
      content: content.trim(),
      createdBy: user.uid,
      createdByName: user.displayName ?? user.email ?? 'ログインユーザー',
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );

    await _issues(playerId).add(issue.toJson());
  }

  Future<void> updateIssue({
    required String playerId,
    required String issueId,
    required String content,
  }) async {
    await _issues(playerId).doc(issueId).update({
      'content': content.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> softDeleteIssue({
    required String playerId,
    required String issueId,
  }) async {
    await _issues(playerId).doc(issueId).update({
      'deletedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> addComment({
    required String playerId,
    required String issueId,
    required String content,
  }) async {
    final user = _requireUser();
    final now = DateTime.now();

    final comment = PlayerIssueComment(
      id: '',
      content: content.trim(),
      createdBy: user.uid,
      createdByName: user.displayName ?? user.email ?? 'ログインユーザー',
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );

    await _comments(playerId: playerId, issueId: issueId).add(comment.toJson());
  }

  Future<void> updateComment({
    required String playerId,
    required String issueId,
    required String commentId,
    required String content,
  }) async {
    await _comments(playerId: playerId, issueId: issueId)
        .doc(commentId)
        .update({
      'content': content.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> softDeleteComment({
    required String playerId,
    required String issueId,
    required String commentId,
  }) async {
    await _comments(playerId: playerId, issueId: issueId)
        .doc(commentId)
        .update({
      'deletedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('ログインユーザーが見つかりません。');
    }
    return user;
  }
}