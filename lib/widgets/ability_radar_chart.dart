import 'dart:math';
import 'package:flutter/material.dart';

class AbilityRadarChart extends StatelessWidget {
  const AbilityRadarChart({super.key, required this.values});

  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: CustomPaint(
        painter: _RadarChartPainter(values),
        child: Container(),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter(this.values);

  final Map<String, int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.35;
    final labels = values.keys.toList();
    final count = labels.length;

    final gridPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke;

    final valuePaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final valueLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int level = 1; level <= 5; level++) {
      final path = Path();
      final r = radius * level / 5;

      for (int i = 0; i < count; i++) {
        final angle = -pi / 2 + 2 * pi * i / count;
        final point = Offset(
          center.dx + cos(angle) * r,
          center.dy + sin(angle) * r,
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final valuePath = Path();

    for (int i = 0; i < count; i++) {
      final label = labels[i];
      final value = values[label]!.clamp(1, 10);
      final r = radius * value / 10;
      final angle = -pi / 2 + 2 * pi * i / count;

      final point = Offset(
        center.dx + cos(angle) * r,
        center.dy + sin(angle) * r,
      );

      final edge = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawLine(center, edge, gridPaint);

      if (i == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelPoint = Offset(
        center.dx + cos(angle) * (radius + 24),
        center.dy + sin(angle) * (radius + 24),
      );

      textPainter.paint(
        canvas,
        labelPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    valuePath.close();
    canvas.drawPath(valuePath, valuePaint);
    canvas.drawPath(valuePath, valueLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
