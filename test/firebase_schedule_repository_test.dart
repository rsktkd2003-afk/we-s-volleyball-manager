// SDKの呼び出し引数を捕捉する境界テスト。実際の通信・Rulesは検証しない。
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/schedule_template.dart';
import 'package:volleyball_app/models/team_schedule.dart';
import 'package:volleyball_app/repositories/schedule_repository.dart';

class _State {
  final values = <String, Map<String, dynamic>>{};
  final writes = <String, Map<Object, Object?>>{};
  final deleted = <String>[];
  final queries = <String>[];
  Object? writeError;
}

class _User extends Fake implements User {
  _User(this.uid, this.displayName);
  @override
  final String uid;
  @override
  final String? displayName;
}

class _Auth extends Fake implements FirebaseAuth {
  User? user = _User('u1', ' Auth Name ');
  @override
  User? get currentUser => user;
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);
  final Map<String, dynamic>? value;
  @override
  Map<String, dynamic>? data() => value;
}

class _QueryDoc extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDoc(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
}

class _QuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.state, this.path);
  final _State state;
  @override
  final String path;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(state.values[path]);
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Collection(state, '$path/$name');
  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (state.writeError != null) throw state.writeError!;
    state.writes[path] = Map.of(data);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (state.writeError != null) throw state.writeError!;
    state.writes[path] = Map.of(data);
  }

  @override
  Future<void> delete() async {
    state.deleted.add(path);
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.state, this.path);
  final _State state;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Document(state, '$path/${id ?? 'generated'}');
  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    final document = doc();
    await document.set(data);
    return document;
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    state.queries.add('$path:$field:$descending');
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final prefix = '$path/';
    return _QuerySnapshot([
      for (final entry in state.values.entries)
        if (entry.key.startsWith(prefix) &&
            !entry.key.substring(prefix.length).contains('/'))
          _QueryDoc(entry.key.substring(prefix.length), entry.value),
    ]);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.fromFuture(get());
}

class _Firestore extends Fake implements FirebaseFirestore {
  _Firestore(this.state);
  final _State state;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(state, path);
}

void main() {
  late _State state;
  late _Auth auth;
  late FirebaseScheduleRepository repository;
  final start = DateTime(2026, 10, 16, 19);

  setUp(() {
    state = _State();
    auth = _Auth();
    repository = FirebaseScheduleRepository(
      firestore: _Firestore(state),
      auth: auth,
    );
  });

  test('予定追加・編集・削除は既存のパス・値でSDKを呼ぶ', () async {
    final schedule = TeamSchedule(
      title: '練習',
      location: '体育館',
      start: start,
      end: start.add(const Duration(minutes: 90)),
      durationMinutes: 90,
      color: Colors.blue,
      createdBy: 'u1',
    );
    await repository.addSchedule(schedule);
    expect(state.writes['schedules/generated'], schedule.toJson());
    await repository.updateSchedule(
      id: 's1',
      title: ' 新タイトル ',
      location: '会場',
      start: start,
      durationMinutes: 60,
    );
    expect(state.writes['schedules/s1'], {
      'title': ' 新タイトル ',
      'location': '会場',
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(start.add(const Duration(hours: 1))),
      'durationMinutes': 60,
    });
    expect(state.writes['schedules/s1']!.containsKey('createdBy'), isFalse);
    await repository.deleteSchedule('s1');
    expect(state.deleted, ['schedules/s1']);
  });

  test('予定取得・購読でstart昇順を要求し、IDを復元する', () async {
    state.values['schedules/s1'] = {
      'title': '練習',
      'location': '',
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(start),
      'durationMinutes': 0,
    };
    expect((await repository.fetchSchedules()).single.id, 's1');
    expect((await repository.watchSchedules().first).single.title, '練習');
    expect(state.queries, ['schedules:start:false', 'schedules:start:false']);
  });

  test('テンプレート追加・購読・削除の形式を維持する', () async {
    final template = ScheduleTemplate(
      title: '練習',
      location: '体育館',
      durationMinutes: 90,
    );
    await repository.addTemplate(template);
    expect(state.writes['schedule_templates/generated'], template.toJson());
    state.values['schedule_templates/t1'] = template.toJson();
    expect((await repository.watchTemplates().first).single.id, 't1');
    await repository.deleteTemplate('t1');
    expect(state.deleted, ['schedule_templates/t1']);
  });

  for (final input in [
    (
      data: <String, dynamic>{
        'displayName': ' Stored Name ',
        'playerId': ' p1 ',
      },
      expectedName: 'Stored Name',
      expectedId: 'p1',
    ),
    (
      data: <String, dynamic>{'displayName': ' ', 'playerId': ''},
      expectedName: 'Auth Name',
      expectedId: 'u1',
    ),
    (data: <String, dynamic>{}, expectedName: 'Auth Name', expectedId: 'u1'),
  ]) {
    test(
      '出欠保存の名前・選手IDのfallback：${input.data}',
      () async {
        state.values['users/u1'] = input.data;
        await repository.saveResponse(
          scheduleId: 's1',
          status: '遅刻',
          lateTime: '未定',
        );
        final data = state.writes['schedules/s1/responses/u1']!;
        expect(data, {
          'uid': 'u1',
          'playerId': input.expectedId,
          'playerName': input.expectedName,
          'status': '遅刻',
          'lateTime': '未定',
          'updatedAt': isA<FieldValue>(),
        });
      },
    );
  }

  test('Authにも名前がないときは既定名を使う', () async {
    auth.user = _User('u1', ' ');
    await repository.saveResponse(scheduleId: 's1', status: '参加', lateTime: '');
    expect(
      state.writes['schedules/s1/responses/u1']!['playerName'],
      'ログインユーザー',
    );
  });

  test('出欠購読は一覧の順序と欠落値のfallbackを維持する', () async {
    state.values['schedules/s1/responses/u1'] = {
      'playerName': '山田',
      'status': '参加',
    };
    state.values['schedules/s1/responses/u2'] = {};
    final responses = await repository.watchResponses('s1').first;
    expect(responses.map((response) => response.playerName), ['山田', '']);
    expect(responses.last.status, '');
    expect(responses.last.lateTime, '');
  });

  test('未ログインの出欠操作は書き込みを行わず、roleも許可しない', () async {
    auth.user = null;
    await repository.saveResponse(scheduleId: 's1', status: '参加', lateTime: '');
    await repository.deleteMyResponse('s1');
    expect(state.writes, isEmpty);
    expect(state.deleted, isEmpty);
    expect(await repository.isCurrentUserAdmin(), isFalse);
  });

  test('削除操作とrole取得は現在のユーザーを使う', () async {
    auth.user = _User('u2', null);
    state.values['users/u2'] = {'role': 'admin'};
    expect(repository.currentUid, 'u2');
    expect(await repository.isCurrentUserAdmin(), isTrue);
    await repository.deleteMyResponse('s1');
    expect(state.deleted, ['schedules/s1/responses/u2']);
  });

  test('SDKの書き込み失敗を成功に変換しない', () async {
    final error = StateError('permission-denied');
    state.writeError = error;
    await expectLater(
      repository.saveResponse(scheduleId: 's1', status: '参加', lateTime: ''),
      throwsA(same(error)),
    );
  });
}
