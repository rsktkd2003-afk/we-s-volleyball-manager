import 'dart:math';
import 'package:flutter/material.dart';

/// 体育館のコルク掲示板風の背景。
/// 画像アセット不要・固定シードで模様は毎回同じ。
class CorkBoardBackground extends StatelessWidget {
  const CorkBoardBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCBA468), Color(0xFFB98C4F)],
        ),
      ),
      child: CustomPaint(
        painter: _CorkPainter(),
        child: child,
      ),
    );
  }
}

class _CorkPainter extends CustomPainter {
  static const int _grainCount = 900; // コルクの粒
  static const int _holeCount = 14; // ピン穴

  @override
  void paint(Canvas canvas, Size size) {
    // 日焼け感（四隅をわずかに濃く）
    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 0.9,
        colors: const [Color(0x00000000), Color(0x22000000)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    final rnd = Random(7); // 固定シード
    final dark = Paint()..color = const Color(0x1E000000);
    final light = Paint()..color = const Color(0x14FFFFFF);

    // コルクの粒感
    for (int i = 0; i < _grainCount; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.5 + 0.3;
      canvas.drawCircle(Offset(dx, dy), r, rnd.nextBool() ? dark : light);
    }

    // 小さなピン穴
    final holeDark = Paint()..color = const Color(0x33000000);
    final holeLight = Paint()..color = const Color(0x22FFFFFF);
    for (int i = 0; i < _holeCount; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.8, holeDark);
      canvas.drawCircle(Offset(dx - 0.6, dy - 0.6), 0.8, holeLight);
    }
  }

  @override
  bool shouldRepaint(covariant _CorkPainter oldDelegate) => false;
}