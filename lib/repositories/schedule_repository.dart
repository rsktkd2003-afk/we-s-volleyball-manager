import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/schedule_template.dart';
import '../models/team_schedule.dart';

/// schedules / schedule_templates / 出欠(responses) への
/// Firestore アクセスを一元化する。
/// 単一チーム運用のため teamId フィルタは使わない。
class ScheduleRepository {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _schedules =>
      _db.collection('schedules');

  static CollectionReference<Map<String, dynamic>> get _templates =>
      _db.collection('schedule_templates');

  static CollectionReference<Map<String, dynamic>> _responses(
    String scheduleId,
  ) => _schedules.doc(scheduleId).collection('responses');

  // ---------- schedules ----------

  static Stream<List<TeamSchedule>> watchSchedules() {
    return _schedules.orderBy('start').snapshots().map(_toSchedules);
  }

  static Future<List<TeamSchedule>> fetchSchedules() async {
    return _toSchedules(await _schedules.orderBy('start').get());
  }

  static List<TeamSchedule> _toSchedules(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => TeamSchedule.fromJson(doc.data(), doc.id))
        .toList();
  }

  static Future<void> addSchedule(TeamSchedule schedule) {
    return _schedules.add(schedule.toJson());
  }

  static Future<void> updateSchedule(String id, Map<String, dynamic> data) {
    return _schedules.doc(id).update(data);
  }

  static Future<void> deleteSchedule(String id) {
    return _schedules.doc(id).delete();
  }

  // ---------- schedule_templates ----------

  static Stream<List<ScheduleTemplate>> watchTemplates() {
    return _templates.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ScheduleTemplate.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }

  static Future<void> addTemplate(ScheduleTemplate template) {
    return _templates.add(template.toJson());
  }

  static Future<void> deleteTemplate(String id) {
    return _templates.doc(id).delete();
  }

  // ---------- 出欠 (responses) ----------

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchResponses(
    String scheduleId,
  ) {
    return _responses(scheduleId).snapshots();
  }

  static Future<void> saveResponse({
    required String scheduleId,
    required String status,
    required String lateTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _responses(scheduleId).doc(user.uid).set({
      'uid': user.uid,
      'playerId': user.uid,
      'playerName': user.displayName ?? user.email ?? 'ログインユーザー',
      'status': status,
      'lateTime': lateTime,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMyResponse(String scheduleId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _responses(scheduleId).doc(uid).delete();
  }
}