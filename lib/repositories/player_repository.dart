import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/player.dart';
import '../utils/firestore_collections.dart';

/// players コレクションの読み書きを提供する。
abstract interface class PlayerRepository {
  Stream<List<Player>> watchPlayers();

  /// 名前と既存の初期値で選手を追加する。所有者は実行時の認証ユーザー。
  Future<void> addPlayer(String name);

  /// 選手編集画面で編集できる項目([Player.toEditableJson])だけを更新する。
  /// ownerUid・linkedUid・編集対象外の項目は書き込まない。
  Future<void> updateEditableFields(Player player);

  /// 選手データを削除する。
  Future<void> deletePlayer(String playerId);
}

class FirebasePlayerRepository implements PlayerRepository {
  FirebasePlayerRepository({FirebaseFirestore? firestore, this.auth})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  // 読み取り・編集・削除だけではAuthの初期化を要求しない。
  final FirebaseAuth? auth;

  CollectionReference<Map<String, dynamic>> get _players =>
      _firestore.collection(FirestoreCollections.players);

  @override
  Stream<List<Player>> watchPlayers() {
    return _players.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Player.fromJson(doc.data(), id: doc.id))
          .toList();
    });
  }

  @override
  Future<void> addPlayer(String name) async {
    final player = Player(
      name: name.trim(),
      number: 0,
      position: '未設定',
      dominantHand: '右',
      grade: '未設定',
      height: 0.0,
      weight: 0.0,
      standingReach: 0.0,
      maxReach: 0.0,
      blockReach: 0.0,
    );
    await _players.add({
      ...player.toJson(),
      'ownerUid': (auth ?? FirebaseAuth.instance).currentUser?.uid,
    });
  }

  @override
  Future<void> updateEditableFields(Player player) {
    return _players.doc(player.id).update(player.toEditableJson());
  }

  @override
  Future<void> deletePlayer(String playerId) {
    return _players.doc(playerId).delete();
  }
}
