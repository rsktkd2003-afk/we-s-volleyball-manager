import 'package:flutter/material.dart';

/// 掲示板の世界観に寄せた赤ピン/スタンプ風FAB。挙動は標準FABと同一。
class WesFab extends StatelessWidget {
  const WesFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Color(0x4DB71C1C),
          ),
        ],
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
          stops: [0.0, 1.0],
        ),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}