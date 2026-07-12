import 'package:flutter/material.dart';

/// 選手の役職。Firestoreには内部値（英語キー）の文字列配列として保存する。
class PlayerRoles {
  PlayerRoles._();

  static const String captain = 'captain';
  static const String viceCaptain = 'viceCaptain';
  static const String sns = 'sns';
  static const String contact = 'contact';
  static const String gymBooking = 'gymBooking';
  static const String practiceLeader = 'practiceLeader';

  static const List<String> all = [
    captain,
    viceCaptain,
    sns,
    contact,
    gymBooking,
    practiceLeader,
  ];

  static const Map<String, String> _displayNames = {
    captain: 'キャプテン',
    viceCaptain: '副キャプテン',
    sns: 'SNS係',
    contact: '連絡係',
    gymBooking: '体育館予約係',
    practiceLeader: '練習リーダー',
  };

  static const Map<String, IconData> _icons = {
    captain: Icons.workspace_premium_outlined,
    viceCaptain: Icons.star_outline,
    sns: Icons.camera_alt_outlined,
    contact: Icons.chat_bubble_outline,
    gymBooking: Icons.key_outlined,
    practiceLeader: Icons.assignment_outlined,
  };

  static String displayName(String role) => _displayNames[role] ?? role;

  static IconData iconFor(String role) => _icons[role] ?? Icons.help_outline;
}
