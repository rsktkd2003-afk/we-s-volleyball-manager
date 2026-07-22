import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/player.dart';
import '../models/player_link_request.dart';
import '../utils/firestore_collections.dart';

abstract interface class PlayerLinkRequestRepository {
  Future<List<Player>> loadUnlinkedPlayers();

  Future<PlayerLinkRequest?> loadMyPendingRequest();

  Stream<List<PlayerLinkRequest>> watchPendingRequests();

  Future<void> createRequest({
    required String playerId,
    required String playerName,
  });

  Future<void> approveRequest(String requestId);

  Future<void> rejectRequest(String requestId);

  Future<void> unlinkPlayer({
    required String uid,
    required String playerId,
  });
}

class FirebasePlayerLinkRequestRepository
    implements PlayerLinkRequestRepository {
  FirebasePlayerLinkRequestRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _players =>
      _firestore.collection(FirestoreCollections.players);

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(FirestoreCollections.playerLinkRequests);

  @override
  Future<List<Player>> loadUnlinkedPlayers() async {
    final snapshot = await _players.where('linkedUid', isNull: true).get();

    return snapshot.docs
        .map((doc) => Player.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<PlayerLinkRequest?> loadMyPendingRequest() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snapshot = await _requests.where('uid', isEqualTo: uid).get();

    for (final doc in snapshot.docs) {
      final request = PlayerLinkRequest.fromJson(doc.data(), id: doc.id);
      if (request.isPending) return request;
    }

    return null;
  }

  @override
  Stream<List<PlayerLinkRequest>> watchPendingRequests() {
    return _requests
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => PlayerLinkRequest.fromJson(doc.data(), id: doc.id))
          .toList();
      requests.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
      return requests;
    });
  }

  @override
  Future<void> createRequest({
    required String playerId,
    required String playerName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('ログイン情報が見つかりません');
    }

    final userDoc = await _users.doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) {
      throw StateError('ユーザー情報が見つかりません');
    }

    final currentPlayerId = userData['playerId'] as String?;
    if (currentPlayerId != null && currentPlayerId.isNotEmpty) {
      throw StateError('すでに選手データと連携済みです');
    }

    final pending = await loadMyPendingRequest();
    if (pending != null) {
      throw StateError('すでに連携申請中です');
    }

    final playerDoc = await _players.doc(playerId).get();
    final playerData = playerDoc.data();
    if (playerData == null) {
      throw StateError('選手データが見つかりません');
    }

    final linkedUid = playerData['linkedUid'];
    if (linkedUid != null && linkedUid.toString().isNotEmpty) {
      throw StateError('この選手はすでに連携済みです');
    }

    final request = PlayerLinkRequest(
      uid: user.uid,
      playerId: playerId,
      playerName: playerName,
      displayName: user.displayName ?? user.email ?? '',
    );

    await _requests.add(request.toJson());
  }

  @override
  Future<void> approveRequest(String requestId) async {
    final adminUid = _requireUid();

    await _firestore.runTransaction((transaction) async {
      final requestRef = _requests.doc(requestId);
      final requestDoc = await transaction.get(requestRef);
      final requestData = requestDoc.data();

      if (requestData == null) {
        throw StateError('申請が見つかりません');
      }
      if (requestData['status'] != 'pending') {
        throw StateError('この申請はすでに処理済みです');
      }

      final uid = requestData['uid'] as String?;
      final playerId = requestData['playerId'] as String?;
      if (uid == null || uid.isEmpty || playerId == null || playerId.isEmpty) {
        throw StateError('申請データが不正です');
      }

      final userRef = _users.doc(uid);
      final playerRef = _players.doc(playerId);
      final userDoc = await transaction.get(userRef);
      final playerDoc = await transaction.get(playerRef);
      final userData = userDoc.data();
      final playerData = playerDoc.data();

      if (userData == null) {
        throw StateError('ユーザー情報が見つかりません');
      }
      if (playerData == null) {
        throw StateError('選手情報が見つかりません');
      }

      final userPlayerId = userData['playerId'];
      if (userPlayerId != null && userPlayerId.toString().isNotEmpty) {
        throw StateError('このユーザーはすでに選手と連携済みです');
      }

      final linkedUid = playerData['linkedUid'];
      if (linkedUid != null && linkedUid.toString().isNotEmpty) {
        throw StateError('この選手はすでに他のユーザーと連携済みです');
      }

      transaction.update(userRef, {
        'playerId': playerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(playerRef, {'linkedUid': uid});
      transaction.update(requestRef, {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      });
    });
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    final adminUid = _requireUid();

    await _requests.doc(requestId).update({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
    });
  }

  @override
  Future<void> unlinkPlayer({
    required String uid,
    required String playerId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _users.doc(uid);
      final playerRef = _players.doc(playerId);
      final userDoc = await transaction.get(userRef);
      final playerDoc = await transaction.get(playerRef);

      if (!userDoc.exists) {
        throw StateError('ユーザー情報が見つかりません');
      }
      if (!playerDoc.exists) {
        throw StateError('選手情報が見つかりません');
      }

      transaction.update(userRef, {
        'playerId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(playerRef, {'linkedUid': null});
    });
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('ログイン情報が見つかりません');
    }
    return uid;
  }
}
