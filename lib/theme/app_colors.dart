import 'package:flutter/material.dart';

/// Shared color palette reused across screens and widgets, extracted to
/// avoid re-declaring the same hex literals in every file.
class AppColors {
  AppColors._();

  /// Team accent color - used for danger/delete actions, pins, and highlights.
  static const Color accent = Color(0xFFD32F2F);

  /// Primary actions. Danger actions retain the team red.
  static const Color action = Color(0xFF17314F);

  /// Editorial accent used for volleyball branding and selected dates.
  static const Color editorialAccent = Color(0xFFE14B3B);

  /// Cream paper background used behind card/sticky-note style widgets.
  static const Color paper = Color(0xFFFFF9F0);

  /// Primary body text color.
  static const Color textPrimary = Color(0xFF172B43);

  /// Secondary/muted text color.
  static const Color textSecondary = Color(0xFF5C6672);

  /// Near-black background used for the top brand header bar.
  static const Color headerDark = Color(0xFF13253A);

  /// Flat light background behind the player scouting board.
  static const Color boardBackground = Color(0xFFF4F1EA);
}
