import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/firestore_collections.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // users
  static CollectionReference<Map<String, dynamic>> get usersRef =>
      _db.collection(FirestoreCollections.users);

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
}
