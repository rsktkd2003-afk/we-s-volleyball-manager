import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/firestore_collections.dart';

/// 認証状態と users/{uid} ドキュメントの監視を提供する。
abstract interface class CurrentUserRepository {
  /// ログイン中ユーザーの uid。未ログインなら null。
  Stream<String?> watchAuthUid();

  /// users/{uid} の内容。ドキュメントが存在しなければ null。
  Stream<Map<String, dynamic>?> watchUserData(String uid);
}

class FirebaseCurrentUserRepository implements CurrentUserRepository {
  FirebaseCurrentUserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<String?> watchAuthUid() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Stream<Map<String, dynamic>?> watchUserData(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
}
