import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/account_profile.dart';
import '../utils/account_validation.dart';
import '../utils/firestore_collections.dart';
import 'notification_service.dart';

class AccountService {
  AccountService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection(FirestoreCollections.users).doc(uid);

  static Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final validationError = validateDisplayName(displayName);
    if (validationError != null) {
      throw ArgumentError(validationError, 'displayName');
    }

    final normalizedDisplayName = normalizeDisplayName(displayName);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = credential.user;

    if (user == null) {
      throw StateError('登録したユーザー情報を取得できませんでした');
    }

    await user.updateDisplayName(normalizedDisplayName);
    await ensureUserDocument(user, displayName: normalizedDisplayName);
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = credential.user;

    if (user == null) {
      throw StateError('ログインしたユーザー情報を取得できませんでした');
    }

    await ensureUserDocument(user);
  }

  static Future<void> ensureUserDocument(
    User user, {
    String? displayName,
  }) async {
    final normalizedDisplayName = displayName == null
        ? null
        : normalizeDisplayName(displayName);
    final authDisplayName = normalizeDisplayName(user.displayName ?? '');
    final userRef = _userRef(user.uid);

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final now = FieldValue.serverTimestamp();

      if (!userDoc.exists) {
        transaction.set(userRef, {
          'email': user.email,
          'displayName': normalizedDisplayName ?? authDisplayName,
          'role': 'member',
          'playerId': null,
          'createdAt': now,
          'updatedAt': now,
        });
        return;
      }

      final data = userDoc.data() ?? <String, dynamic>{};
      final storedDisplayName =
          normalizeDisplayName(data['displayName'] as String? ?? '');
      final updates = <String, dynamic>{'updatedAt': now};

      if (!data.containsKey('email')) {
        updates['email'] = user.email;
      }

      if (normalizedDisplayName != null) {
        updates['displayName'] = normalizedDisplayName;
      } else if (storedDisplayName.isEmpty && authDisplayName.isNotEmpty) {
        updates['displayName'] = authDisplayName;
      } else if (!data.containsKey('displayName')) {
        updates['displayName'] = '';
      }

      if (!data.containsKey('role')) {
        updates['role'] = 'member';
      }

      if (!data.containsKey('playerId') || data['playerId'] == '') {
        updates['playerId'] = null;
      }

      transaction.set(userRef, updates, SetOptions(merge: true));
    });
  }

  static Future<AccountProfile> loadCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('ログイン情報が見つかりません');
    }

    await ensureUserDocument(user);
    final data = (await _userRef(user.uid).get()).data();
    final storedDisplayName =
        normalizeDisplayName(data?['displayName'] as String? ?? '');

    return AccountProfile(
      email: user.email ?? (data?['email'] as String?) ?? '',
      displayName: storedDisplayName.isNotEmpty
          ? storedDisplayName
          : normalizeDisplayName(user.displayName ?? ''),
    );
  }

  static Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('ログイン情報が見つかりません');
    }

    final validationError = validateDisplayName(displayName);
    if (validationError != null) {
      throw ArgumentError(validationError, 'displayName');
    }

    final normalizedDisplayName = normalizeDisplayName(displayName);
    await user.updateDisplayName(normalizedDisplayName);
    await _userRef(user.uid).set({
      'email': user.email,
      'displayName': normalizedDisplayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> signOut() async {
    await NotificationService.detachCurrentUser();
    await _auth.signOut();
  }
}
