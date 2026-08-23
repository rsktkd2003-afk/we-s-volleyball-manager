import 'package:flutter/material.dart';

/// 予定の種類を、カレンダーと日別一覧で共通の色に変換する。
Color scheduleColorForTitle(String title) {
  if (title.contains('ウェイト')) {
    return const Color(0xFFFAD4D8);
  }

  if (title.contains('試合') || title.contains('公式戦') || title.contains('大会')) {
    return const Color(0xFFFFF3B0);
  }

  return const Color(0xFFCDEFFF);
}
