import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/player.dart';
import '../models/player_link_request.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // users
  static CollectionReference<Map<String, dynamic>> get usersRef =>
      _db.collection('users');

  static Future<Map<String, dynamic>?> loadCurrentUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await usersRef.doc(uid).get();
    return doc.data();
  }

  static Future<bool> isCurrentUserAdmin() async {
    final data = await loadCurrentUserData();
    return data?['role'] == 'admin';
  }

  // players
  static CollectionReference<Map<String, dynamic>> get playersRef =>
      _db.collection('players');

  static Future<List<Player>> loadUnlinkedPlayers() async {
    final query = playersRef.where('linkedUid', isNull: true);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => Player.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  // player link requests
  static CollectionReference<Map<String, dynamic>> get playerLinkRequestsRef =>
      _db.collection('player_link_requests');

  static Future<PlayerLinkRequest?> loadMyPendingPlayerLinkRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return null;

    final snapshot = await playerLinkRequestsRef
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return PlayerLinkRequest.fromJson(doc.data(), id: doc.id);
  }

  static Future<List<PlayerLinkRequest>> loadPendingPlayerLinkRequests() async {
    final snapshot = await playerLinkRequestsRef
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => PlayerLinkRequest.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  static Future<void> createPlayerLinkRequest({
    required String playerId,
    required String playerName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await loadCurrentUserData();

    if (user == null || userData == null) {
      throw Exception('ログイン情報が見つかりません');
    }

    final currentPlayerId = userData['playerId'] as String?;
    if (currentPlayerId != null && currentPlayerId.isNotEmpty) {
      throw Exception('すでに選手データと連携済みです');
    }

    final pending = await loadMyPendingPlayerLinkRequest();
    if (pending != null) {
      throw Exception('すでに連携申請中です');
    }

    final playerDoc = await playersRef.doc(playerId).get();
    final playerData = playerDoc.data();

    if (!playerDoc.exists || playerData == null) {
      throw Exception('選手データが見つかりません');
    }

    if (playerData['linkedUid'] != null &&
        playerData['linkedUid'].toString().isNotEmpty) {
      throw Exception('この選手はすでに連携済みです');
    }

    final request = PlayerLinkRequest(
      uid: user.uid,
      playerId: playerId,
      playerName: playerName,
      displayName: user.displayName ?? user.email ?? '',
    );

    await playerLinkRequestsRef.add(request.toJson());
  }

  static Future<void> approvePlayerLinkRequest(String requestId) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) {
      throw Exception('ログイン情報が見つかりません');
    }

    await _db.runTransaction((transaction) async {
      final requestRef = playerLinkRequestsRef.doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists) {
        throw Exception('申請が見つかりません');
      }

      final requestData = requestDoc.data()!;
      if (requestData['status'] != 'pending') {
        throw Exception('この申請はすでに処理済みです');
      }

      final uid = requestData['uid'] as String;
      final playerId = requestData['playerId'] as String;

      final userRef = usersRef.doc(uid);
      final playerRef = playersRef.doc(playerId);

      final userDoc = await transaction.get(userRef);
      final playerDoc = await transaction.get(playerRef);

      if (!userDoc.exists) {
        throw Exception('ユーザー情報が見つかりません');
      }

      if (!playerDoc.exists) {
        throw Exception('選手情報が見つかりません');
      }

      final userData = userDoc.data()!;
      final playerData = playerDoc.data()!;

      final userPlayerId = userData['playerId'];
      if (userPlayerId != null && userPlayerId.toString().isNotEmpty) {
        throw Exception('このユーザーはすでに選手と連携済みです');
      }

      final linkedUid = playerData['linkedUid'];
      if (linkedUid != null && linkedUid.toString().isNotEmpty) {
        throw Exception('この選手はすでに他のユーザーと連携済みです');
      }

      transaction.update(userRef, {
        'playerId': playerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(playerRef, {
        'linkedUid': uid,
      });

      transaction.update(requestRef, {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      });
    });
  }

  static Future<void> rejectPlayerLinkRequest(String requestId) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) {
      throw Exception('ログイン情報が見つかりません');
    }

    await playerLinkRequestsRef.doc(requestId).update({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
    });
  }

  static Future<void> unlinkPlayer({
    required String uid,
    required String playerId,
  }) async {
    await _db.runTransaction((transaction) async {
      final userRef = usersRef.doc(uid);
      final playerRef = playersRef.doc(playerId);

      final userDoc = await transaction.get(userRef);
      final playerDoc = await transaction.get(playerRef);

      if (!userDoc.exists) {
        throw Exception('ユーザー情報が見つかりません');
      }

      if (!playerDoc.exists) {
        throw Exception('選手情報が見つかりません');
      }

      transaction.update(userRef, {
        'playerId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(playerRef, {
        'linkedUid': null,
      });
    });
  }
}