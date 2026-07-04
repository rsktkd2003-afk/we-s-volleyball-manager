import 'package:flutter/material.dart';

import 'pin_badge.dart';

/// コルクボードに大きな紙を画鋲2つで貼った見た目。中身はそのまま差し込む。
class PinnedPaperCard extends StatelessWidget {
  const PinnedPaperCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 12),
    this.padding = const EdgeInsets.fromLTRB(30, 42, 30, 30),
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xFFFCFAF4), // 少しだけ生成りの紙
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  offset: Offset(0, 8),
                  color: Color(0x40000000),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          const Positioned(
            top: -7,
            left: 28,
            child: PinBadge(color: Color(0xFFD32F2F), size: 20),
          ),
          const Positioned(
            top: -7,
            right: 28,
            child: PinBadge(color: Color(0xFF1976D2), size: 20),
          ),
        ],
      ),
    );
  }
}