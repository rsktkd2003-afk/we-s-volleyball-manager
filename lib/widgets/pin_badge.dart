import 'package:flutter/material.dart';

/// 画鋲（プッシュピン）風の丸い装飾。
/// seed を渡すと色・微小角度・位置ずれが index/id から決定的に決まる。
class PinBadge extends StatelessWidget {
  const PinBadge({
    super.key,
    this.color = const Color(0xFFD32F2F),
    this.seed,
    this.size = 18,
  });

  final Color color;
  final int? seed;
  final double size;

  static const List<Color> _palette = [
    Color(0xFFD32F2F), // 赤（チームカラー）
    Color(0xFF1976D2), // 青
    Color(0xFF388E3C), // 緑
    Color(0xFF7B1FA2), // 紫
    Color(0xFFF9A825), // 琥珀
  ];

  @override
  Widget build(BuildContext context) {
    final s = seed;
    final base = s == null ? color : _palette[s.abs() % _palette.length];
    final tilt = s == null ? 0.0 : ((s.abs() % 7) - 3) * 0.05;

    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              Color.lerp(base, Colors.white, 0.6)!,
              base,
              Color.lerp(base, Colors.black, 0.28)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 3,
              offset: Offset(0, 2),
              color: Color(0x55000000),
            ),
          ],
        ),
      ),
    );
  }
}