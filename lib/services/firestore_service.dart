import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';
import '../models/practice.dart';
import '../models/practice_template.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // players
  static CollectionReference<Map<String, dynamic>> get playersRef =>
      _db.collection('players');

  static Future<List<Player>> loadPlayers() async {
    final snapshot = await playersRef.get();

    return snapshot.docs
        .map((doc) => Player.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  static Future<void> savePlayer(Player player) async {
    await playersRef.doc(player.id).set(player.toJson());
  }

  static Future<void> deletePlayer(String playerId) async {
    await playersRef.doc(playerId).delete();
  }

  // practices
  static CollectionReference<Map<String, dynamic>> get practicesRef =>
      _db.collection('practices');

  static Future<List<Practice>> loadPractices() async {
    final snapshot = await practicesRef.get();

    return snapshot.docs
        .map((doc) => Practice.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  static Future<void> savePractice(Practice practice) async {
    await practicesRef.doc(practice.id).set(practice.toJson());
  }

  static Future<void> deletePractice(String practiceId) async {
    await practicesRef.doc(practiceId).delete();
  }

  // practice templates
  static CollectionReference<Map<String, dynamic>> get practiceTemplatesRef =>
      _db.collection('practice_templates');

  static Future<List<PracticeTemplate>> loadPracticeTemplates() async {
    final snapshot = await practiceTemplatesRef.get();

    return snapshot.docs
        .map((doc) => PracticeTemplate.fromJson(doc.data()))
        .toList();
  }

  static Future<void> savePracticeTemplate(PracticeTemplate template) async {
    await practiceTemplatesRef.doc(template.name).set(template.toJson());
  }

  static Future<void> deletePracticeTemplate(String templateName) async {
    await practiceTemplatesRef.doc(templateName).delete();
  }
}