import 'package:flutter/material.dart';

/// Shared color palette reused across screens and widgets, extracted to
/// avoid re-declaring the same hex literals in every file.
class AppColors {
  AppColors._();

  /// Team accent color - used for danger/delete actions, pins, and highlights.
  static const Color accent = Color(0xFFD32F2F);

  /// Cream paper background used behind card/sticky-note style widgets.
  static const Color paper = Color(0xFFFFFDF7);

  /// Primary body text color.
  static const Color textPrimary = Color(0xFF333333);

  /// Secondary/muted text color.
  static const Color textSecondary = Color(0xFF666666);

  /// Near-black background used for the top brand header bar.
  static const Color headerDark = Color(0xFF1A1A1A);

  /// Flat light background behind the player scouting board.
  static const Color boardBackground = Color(0xFFF2F0EC);
}
