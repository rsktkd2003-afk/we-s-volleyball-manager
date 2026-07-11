import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/match_poll.dart';
import '../models/match_poll_vote.dart';
import '../utils/firestore_collections.dart';

class MatchPollRepository {
  MatchPollRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _polls =>
      _firestore.collection(FirestoreCollections.matchPolls);

  CollectionReference<Map<String, dynamic>> get _schedules =>
      _firestore.collection(FirestoreCollections.schedules);

  CollectionReference<Map<String, dynamic>> _votes(String pollId) {
    return _polls.doc(pollId).collection(FirestoreCollections.votes);
  }

  Stream<List<MatchPoll>> watchPolls() {
    return _polls
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(MatchPoll.fromFirestore)
          .where((poll) => !poll.isDeleted)
          .toList();
    });
  }

  Stream<MatchPoll?> watchPoll(String pollId) {
    return _polls.doc(pollId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return MatchPoll.fromFirestore(snapshot);
    });
  }

  Stream<List<MatchPollVote>> watchVotes(String pollId) {
    return _votes(pollId).snapshots().map((snapshot) {
      return snapshot.docs.map(MatchPollVote.fromFirestore).toList();
    });
  }

  Future<String> addPoll({
    required String title,
    required String note,
    required List<MatchPollCandidate> candidates,
  }) async {
    final uid = _requireUid();
    final now = DateTime.now();

    final poll = MatchPoll(
      id: '',
      title: title.trim(),
      note: note.trim(),
      candidates: candidates,
      status: 'open',
      confirmedCandidateId: null,
      confirmedScheduleId: null,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _polls.add(poll.toJson());
    return docRef.id;
  }

  Future<void> updatePoll({
    required String pollId,
    required String title,
    required String note,
    required List<MatchPollCandidate> candidates,
  }) async {
    await _polls.doc(pollId).update({
      'title': title.trim(),
      'note': note.trim(),
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> softDeletePoll(String pollId) async {
    await _polls.doc(pollId).update({
      'status': 'deleted',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> saveMyVote({
    required String pollId,
    required Map<String, MatchPollAnswer> answers,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('ログインユーザーが見つかりません。');
    }

    final vote = MatchPollVote(
      uid: user.uid,
      displayName: user.displayName ?? user.email ?? 'ログインユーザー',
      answers: answers,
      updatedAt: DateTime.now(),
    );

    await _votes(pollId).doc(user.uid).set(vote.toJson());
  }

  Future<void> deleteMyVote(String pollId) async {
    final uid = _requireUid();
    await _votes(pollId).doc(uid).delete();
  }

  Future<void> confirmPoll({
    required MatchPoll poll,
    required MatchPollCandidate candidate,
  }) async {
    if (!poll.isOpen) {
      throw StateError('この投票はすでに確定済み、または削除済みです。');
    }

    final uid = _requireUid();
    final scheduleRef = _schedules.doc();
    final pollRef = _polls.doc(poll.id);

    final durationMinutes = candidate.end.difference(candidate.start).inMinutes;
    if (durationMinutes <= 0) {
      throw ArgumentError('終了時刻は開始時刻より後にしてください。');
    }

    final batch = _firestore.batch();

    batch.set(scheduleRef, {
      'title': poll.title,
      'location': candidate.location.trim().isEmpty
          ? '未定'
          : candidate.location.trim(),
      'start': Timestamp.fromDate(candidate.start),
      'end': Timestamp.fromDate(candidate.end),
      'durationMinutes': durationMinutes,
      'createdBy': uid,
    });

    batch.update(pollRef, {
      'status': 'confirmed',
      'confirmedCandidateId': candidate.id,
      'confirmedScheduleId': scheduleRef.id,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('ログインユーザーが見つかりません。');
    }
    return uid;
  }
}