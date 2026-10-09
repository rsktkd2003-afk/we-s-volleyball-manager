import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';
import '../utils/firestore_collections.dart';

/// players コレクションの読み取りを提供する。
abstract interface class PlayerRepository {
  Stream<List<Player>> watchPlayers();
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
}
