import 'dart:math';

import 'package:flutter/material.dart';

class AbilityRadarChart extends StatelessWidget {
  const AbilityRadarChart({
    super.key,
    required this.values,
  });

  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: CustomPaint(
        painter: _RadarChartPainter(values),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter(this.values);

  final Map<String, int> values;

  static const Color _red = Color(0xFFC0392B);
  static const Color _gridColor = Color(0xFFBDB8AE);
  static const Color _textColor = Color(0xFF292929);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final labels = values.keys.toList();
    final count = labels.length;

    final center = Offset(
      size.width / 2,
      size.height / 2 + 4,
    );

    final horizontalRadius = max(40.0, size.width / 2 - 58);
    final verticalRadius = max(40.0, size.height / 2 - 52);
    final radius = min(horizontalRadius, verticalRadius);

    final gridPaint = Paint()
      ..color = _gridColor.withValues(alpha: 0.75)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = _gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = _red.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = _red
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = _red
      ..style = PaintingStyle.fill;

    _drawGrid(
      canvas: canvas,
      center: center,
      radius: radius,
      count: count,
      paint: gridPaint,
    );

    _drawAxes(
      canvas: canvas,
      center: center,
      radius: radius,
      count: count,
      paint: axisPaint,
    );

    _drawScaleLabels(
      canvas: canvas,
      center: center,
      radius: radius,
    );

    final valuePath = Path();

    for (int index = 0; index < count; index++) {
      final label = labels[index];
      final rawValue = values[label] ?? 0;
      final value = rawValue.clamp(0, 10);

      final angle = -pi / 2 + (2 * pi * index / count);
      final valueRadius = radius * value / 10;

      final point = Offset(
        center.dx + cos(angle) * valueRadius,
        center.dy + sin(angle) * valueRadius,
      );

      if (index == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }
    }

    valuePath.close();

    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, outlinePaint);

    for (int index = 0; index < count; index++) {
      final label = labels[index];
      final rawValue = values[label] ?? 0;
      final value = rawValue.clamp(0, 10);

      final angle = -pi / 2 + (2 * pi * index / count);
      final valueRadius = radius * value / 10;

      final point = Offset(
        center.dx + cos(angle) * valueRadius,
        center.dy + sin(angle) * valueRadius,
      );

      canvas.drawCircle(point, 3.8, pointPaint);

      _drawAxisLabel(
        canvas: canvas,
        center: center,
        radius: radius,
        angle: angle,
        label: label,
        value: rawValue,
        size: size,
      );
    }
  }

  void _drawGrid({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required int count,
    required Paint paint,
  }) {
    const levels = 5;

    for (int level = 1; level <= levels; level++) {
      final levelRadius = radius * level / levels;
      final path = Path();

      for (int index = 0; index < count; index++) {
        final angle = -pi / 2 + (2 * pi * index / count);

        final point = Offset(
          center.dx + cos(angle) * levelRadius,
          center.dy + sin(angle) * levelRadius,
        );

        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawAxes({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required int count,
    required Paint paint,
  }) {
    for (int index = 0; index < count; index++) {
      final angle = -pi / 2 + (2 * pi * index / count);

      final edge = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawLine(center, edge, paint);
    }
  }

  void _drawScaleLabels({
    required Canvas canvas,
    required Offset center,
    required double radius,
  }) {
    for (int level = 2; level <= 10; level += 2) {
      final levelRadius = radius * level / 10;

      final painter = TextPainter(
        text: TextSpan(
          text: level.toString(),
          style: const TextStyle(
            color: Color(0xFF77736B),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final point = Offset(
        center.dx + 4,
        center.dy - levelRadius - painter.height / 2,
      );

      painter.paint(canvas, point);
    }
  }

  void _drawAxisLabel({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double angle,
    required String label,
    required int value,
    required Size size,
  }) {
    final labelRadius = radius + 31;

    final labelPoint = Offset(
      center.dx + cos(angle) * labelRadius,
      center.dy + sin(angle) * labelRadius,
    );

    final painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(
              color: _textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value.toString(),
            style: const TextStyle(
              color: _textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 84);

    var dx = labelPoint.dx - painter.width / 2;
    var dy = labelPoint.dy - painter.height / 2;

    dx = dx.clamp(0.0, max(0.0, size.width - painter.width));
    dy = dy.clamp(0.0, max(0.0, size.height - painter.height));

    painter.paint(
      canvas,
      Offset(dx, dy),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) {
      return true;
    }

    for (final entry in values.entries) {
      if (oldDelegate.values[entry.key] != entry.value) {
        return true;
      }
    }

    return false;
  }
}