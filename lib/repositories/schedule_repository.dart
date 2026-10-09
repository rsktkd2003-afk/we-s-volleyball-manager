import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/schedule_template.dart';
import '../models/team_schedule.dart';
import '../utils/firestore_collections.dart';

/// 予定・テンプレートの購読元。Provider からテスト用実装へ差し替えられる。
abstract interface class ScheduleReadRepository {
  Stream<List<TeamSchedule>> watchSchedules();

  Stream<List<ScheduleTemplate>> watchTemplates();
}

/// 既存の [ScheduleRepository] に委譲する Firestore 実装。
class FirebaseScheduleReadRepository implements ScheduleReadRepository {
  const FirebaseScheduleReadRepository();

  @override
  Stream<List<TeamSchedule>> watchSchedules() =>
      ScheduleRepository.watchSchedules();

  @override
  Stream<List<ScheduleTemplate>> watchTemplates() =>
      ScheduleRepository.watchTemplates();
}

/// schedules / schedule_templates / 出欠(responses) への
/// Firestore アクセスを一元化する。
class ScheduleRepository {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _schedules =>
      _db.collection(FirestoreCollections.schedules);

  static CollectionReference<Map<String, dynamic>> get _templates =>
      _db.collection(FirestoreCollections.scheduleTemplates);

  static CollectionReference<Map<String, dynamic>> _responses(
    String scheduleId,
  ) => _schedules.doc(scheduleId).collection(FirestoreCollections.responses);

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

    final userDoc = await _db
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();
    final userData = userDoc.data();

    final storedDisplayName =
        (userData?['displayName'] as String? ?? '').trim();
    final authDisplayName = (user.displayName ?? '').trim();
    final displayName = storedDisplayName.isNotEmpty
        ? storedDisplayName
        : authDisplayName.isNotEmpty
            ? authDisplayName
            : 'ログインユーザー';

    final linkedPlayerId = (userData?['playerId'] as String? ?? '').trim();

    await _responses(scheduleId).doc(user.uid).set({
      'uid': user.uid,
      'playerId': linkedPlayerId.isNotEmpty ? linkedPlayerId : user.uid,
      'playerName': displayName,
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
