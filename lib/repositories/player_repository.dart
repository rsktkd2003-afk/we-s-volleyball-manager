import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';
import '../utils/firestore_collections.dart';

/// players コレクションの読み書きを提供する。
abstract interface class PlayerRepository {
  Stream<List<Player>> watchPlayers();

  /// 選手編集画面で編集できる項目([Player.toEditableJson])だけを更新する。
  /// ownerUid・linkedUid・編集対象外の項目は書き込まない。
  Future<void> updateEditableFields(Player player);

  /// 選手データを削除する。
  Future<void> deletePlayer(String playerId);
}

class FirebasePlayerRepository implements PlayerRepository {
  FirebasePlayerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
  Future<void> updateEditableFields(Player player) {
    return _players.doc(player.id).update(player.toEditableJson());
  }

  @override
  Future<void> deletePlayer(String playerId) {
    return _players.doc(playerId).delete();
  }
}
