import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/announcement.dart';
import '../models/team_goal.dart';

class BulletinRepository {
  BulletinRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  CollectionReference<Map<String, dynamic>> get _goals =>
      _firestore.collection('goals');

  Stream<List<Announcement>> watchAnnouncements() {
    return _announcements
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(Announcement.fromFirestore).toList();
    });
  }

  Stream<List<TeamGoal>> watchGoalsForMonth(DateTime month) {
    return _goals
        .where('monthKey', isEqualTo: _monthKey(month))
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(TeamGoal.fromFirestore).toList();
    });
  }

  Future<void> addAnnouncement({
    required String title,
    required String body,
    int sortOrder = 0,
    bool isPinned = false,
  }) async {
    final uid = _requireUid();
    final now = DateTime.now();

    final announcement = Announcement(
      id: '',
      title: title.trim(),
      body: body.trim(),
      sortOrder: sortOrder,
      isPinned: isPinned,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    );

    await _announcements.add(announcement.toJson());
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    required int sortOrder,
    required bool isPinned,
  }) async {
    await _announcements.doc(id).update({
      'title': title.trim(),
      'body': body.trim(),
      'sortOrder': sortOrder,
      'isPinned': isPinned,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _announcements.doc(id).delete();
  }

  Future<void> addGoal({
    required DateTime month,
    required String title,
    required String body,
    int sortOrder = 0,
  }) async {
    final uid = _requireUid();
    final now = DateTime.now();

    final goal = TeamGoal(
      id: '',
      monthKey: _monthKey(month),
      title: title.trim(),
      body: body.trim(),
      sortOrder: sortOrder,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    );

    await _goals.add(goal.toJson());
  }

  Future<void> updateGoal({
    required String id,
    required String title,
    required String body,
    required int sortOrder,
  }) async {
    await _goals.doc(id).update({
      'title': title.trim(),
      'body': body.trim(),
      'sortOrder': sortOrder,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteGoal(String id) async {
    await _goals.doc(id).delete();
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('ログインユーザーが見つかりません。');
    }
    return uid;
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }
}