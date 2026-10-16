import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/schedule_template.dart';
import '../models/schedule_response.dart';
import '../models/team_schedule.dart';
import '../utils/firestore_collections.dart';

/// 予定・テンプレートの購読元。Provider からテスト用実装へ差し替えられる。
abstract interface class ScheduleReadRepository {
  Stream<List<TeamSchedule>> watchSchedules();

  Stream<List<ScheduleTemplate>> watchTemplates();
}

/// 予定・テンプレート・出欠の操作。読み取りの差し替え口は別途維持する。
abstract interface class ScheduleRepository implements ScheduleReadRepository {
  String? get currentUid;
  Future<bool> isCurrentUserAdmin();
  Future<List<TeamSchedule>> fetchSchedules();
  Future<void> addSchedule(TeamSchedule schedule);
  Future<void> updateSchedule({
    required String id,
    required String title,
    required String location,
    required DateTime start,
    required int durationMinutes,
  });
  Future<void> deleteSchedule(String id);
  Future<void> addTemplate(ScheduleTemplate template);
  Future<void> deleteTemplate(String id);
  Stream<List<ScheduleResponse>> watchResponses(String scheduleId);
  Future<void> saveResponse({
    required String scheduleId,
    required String status,
    required String lateTime,
  });
  Future<void> deleteMyResponse(String scheduleId);
}

/// schedules / schedule_templates / 出欠(responses) への
/// Firestore アクセスを一元化する。
class FirebaseScheduleRepository implements ScheduleRepository {
  FirebaseScheduleRepository({FirebaseFirestore? firestore, this.auth})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth? auth;

  FirebaseAuth get _auth => auth ?? FirebaseAuth.instance;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  /// 削除操作の直前に、従来と同じ単発取得でroleを確認する。
  @override
  Future<bool> isCurrentUserAdmin() async {
    final uid = currentUid;
    if (uid == null) return false;
    final doc = await _db.collection(FirestoreCollections.users).doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  CollectionReference<Map<String, dynamic>> get _schedules =>
      _db.collection(FirestoreCollections.schedules);

  CollectionReference<Map<String, dynamic>> get _templates =>
      _db.collection(FirestoreCollections.scheduleTemplates);

  CollectionReference<Map<String, dynamic>> _responses(String scheduleId) =>
      _schedules.doc(scheduleId).collection(FirestoreCollections.responses);

  // ---------- schedules ----------

  @override
  Stream<List<TeamSchedule>> watchSchedules() {
    return _schedules.orderBy('start').snapshots().map(_toSchedules);
  }

  @override
  Future<List<TeamSchedule>> fetchSchedules() async {
    return _toSchedules(await _schedules.orderBy('start').get());
  }

  List<TeamSchedule> _toSchedules(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => TeamSchedule.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addSchedule(TeamSchedule schedule) async {
    await _schedules.add(schedule.toJson());
  }

  @override
  Future<void> updateSchedule({
    required String id,
    required String title,
    required String location,
    required DateTime start,
    required int durationMinutes,
  }) {
    return _schedules.doc(id).update({
      'title': title,
      'location': location,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(start.add(Duration(minutes: durationMinutes))),
      'durationMinutes': durationMinutes,
    });
  }

  @override
  Future<void> deleteSchedule(String id) {
    return _schedules.doc(id).delete();
  }

  // ---------- schedule_templates ----------

  @override
  Stream<List<ScheduleTemplate>> watchTemplates() {
    return _templates.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ScheduleTemplate.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }

  @override
  Future<void> addTemplate(ScheduleTemplate template) async {
    await _templates.add(template.toJson());
  }

  @override
  Future<void> deleteTemplate(String id) {
    return _templates.doc(id).delete();
  }

  // ---------- 出欠 (responses) ----------

  @override
  Stream<List<ScheduleResponse>> watchResponses(String scheduleId) {
    return _responses(scheduleId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ScheduleResponse.fromJson(doc.data()))
          .toList(),
    );
  }

  @override
  Future<void> saveResponse({
    required String scheduleId,
    required String status,
    required String lateTime,
  }) async {
    final user = _auth.currentUser;
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

  @override
  Future<void> deleteMyResponse(String scheduleId) async {
    final uid = currentUid;
    if (uid == null) return;

    await _responses(scheduleId).doc(uid).delete();
  }
}
