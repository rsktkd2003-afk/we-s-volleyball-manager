import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 体育館のコルク掲示板風の背景。
/// 画像アセット不要・固定シードで模様は毎回同じ。
class CorkBoardBackground extends StatelessWidget {
  const CorkBoardBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F7F3), AppColors.boardBackground],
          ),
        ),
        child: child,
      ),
    );
  }
}
