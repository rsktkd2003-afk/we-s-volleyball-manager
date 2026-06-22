import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamService {
  static Future<String> getCurrentTeamId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('ログインしていません');
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final teamId = doc.data()?['teamId'];

    if (teamId == null || teamId.toString().isEmpty) {
      return 'wes';
    }

    return teamId;
  }
}