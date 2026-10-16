// SDK境界に渡した値を検査するテスト用オブジェクト。通信は行わない。
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/repositories/player_repository.dart';
import 'package:volleyball_app/utils/firestore_collections.dart';

import 'support/fake_repositories.dart';

class _Auth extends Fake implements FirebaseAuth {
  User? user;

  @override
  User? get currentUser => user;
}

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final updates = <Map<Object, Object?>>[];
  final deletions = <bool>[];

  Map<Object, Object?>? get updated => updates.lastOrNull;
  bool get deleted => deletions.isNotEmpty;

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updates.add(Map.of(data));
  }

  @override
  Future<void> delete() async {
    deletions.add(true);
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final document = _Document();
  final added = <Map<String, dynamic>>[];
  final documentIds = <String?>[];
  String? get documentId => documentIds.lastOrNull;

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    added.add(Map.of(data));
    return document;
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    documentIds.add(path);
    return document;
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  final players = _Collection();
  String? collectionPath;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    collectionPath = path;
    return players;
  }
}

void main() {
  late _Firestore firestore;
  late _Auth auth;
  late FirebasePlayerRepository repository;

  setUp(() {
    firestore = _Firestore();
    auth = _Auth()..user = _User('owner-1');
    repository = FirebasePlayerRepository(firestore: firestore, auth: auth);
  });

  test('Firebase実装は追加時の所有者・初期値を既存形式で保存する', () async {
    // コンストラクタ時点ではなく、操作時点のUIDを使う。
    auth.user = _User('owner-2');
    await repository.addPlayer('  山田  ');

    expect(firestore.collectionPath, FirestoreCollections.players);
    expect(firestore.players.documentId, isNull); // addで自動IDを使う
    expect(firestore.players.added.single, {
      'ownerUid': 'owner-2',
      'linkedUid': null,
      'name': '山田',
      'number': 0,
      'position': '未設定',
      'dominantHand': '右',
      'grade': '未設定',
      'height': 0.0,
      'weight': 0.0,
      'standingReach': 0.0,
      'maxReach': 0.0,
      'blockReach': 0.0,
      'spike': 5,
      'serve': 5,
      'reception': 5,
      'dig': 5,
      'toss': 5,
      'block': 5,
      'mobility': 5,
      'jump': 5,
      'power': 5,
      'speed': 5,
      'stamina': 5,
      'gameSense': 5,
      'roles': <String>[],
    });
  });

  test('未ログイン時の所有者は従来どおりnullを渡す', () async {
    auth.user = null;
    await repository.addPlayer('山田');
    expect(firestore.players.added.single['ownerUid'], isNull);
  });

  test('Firebase実装のupdateへ編集項目だけを渡す', () async {
    final player = testPlayer(id: 'p1', name: '山田')
      ..ownerUid = 'owner'
      ..linkedUid = 'linked';
    await repository.updateEditableFields(player);

    expect(firestore.players.documentId, 'p1');
    final fields = firestore.players.document.updated!;
    expect(fields, player.toEditableJson());
    for (final excluded in [
      'ownerUid',
      'linkedUid',
      'jump',
      'power',
      'speed',
      'stamina',
      'gameSense',
    ]) {
      expect(fields.containsKey(excluded), isFalse);
    }
  });

  test('Firebase実装は指定IDの選手を削除する', () async {
    await repository.deletePlayer('p1');
    expect(firestore.players.documentId, 'p1');
    expect(firestore.players.document.deleted, isTrue);
  });
}
