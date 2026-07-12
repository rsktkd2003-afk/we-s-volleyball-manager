import 'package:flutter/material.dart';

/// マスキングテープ風の装飾片。
class MaskingTape extends StatelessWidget {
  const MaskingTape({
    super.key,
    required this.angle,
    this.width = 74,
    this.height = 22,
  });

  final double angle;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xB8E4D095),
          border: Border.all(
            color: const Color(0x33A58B4A),
          ),
        ),
      ),
    );
  }
}
