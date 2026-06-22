import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/practice.dart';
import '../models/practice_template.dart';

class StorageService {
  static const String playersKey = 'players';
  static const String practicesKey = 'practices';

  static Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = players.map((player) => player.toJson()).toList();
    await prefs.setString(playersKey, jsonEncode(jsonList));
  }

  static Future<List<Player>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(playersKey);

    if (jsonString == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(jsonString);

    return decoded
        .map((item) => Player.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> savePractices(List<Practice> practices) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = practices.map((practice) => practice.toJson()).toList();
    await prefs.setString(practicesKey, jsonEncode(jsonList));
  }

  static Future<List<Practice>> loadPractices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(practicesKey);

    if (jsonString == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(jsonString);

    return decoded
        .map((item) => Practice.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static const String practiceTemplatesKey = 'practice_templates';

static Future<List<PracticeTemplate>> loadPracticeTemplates() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString(practiceTemplatesKey);

  if (jsonString == null) {
    return [];
  }

  final List<dynamic> jsonList = jsonDecode(jsonString);

  return jsonList
      .map((json) => PracticeTemplate.fromJson(json))
      .toList();
}

static Future<void> savePracticeTemplates(
  List<PracticeTemplate> templates,
) async {
  final prefs = await SharedPreferences.getInstance();

  final jsonString = jsonEncode(
    templates.map((template) => template.toJson()).toList(),
  );

  await prefs.setString(practiceTemplatesKey, jsonString);
}
}