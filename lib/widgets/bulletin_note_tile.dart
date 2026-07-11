import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BulletinNoteTile extends StatelessWidget {
  const BulletinNoteTile({
    super.key,
    required this.heading,
    required this.title,
    required this.body,
    required this.emptyText,
    required this.color,
    required this.rotation,
    required this.pinColor,
    this.onTap,
  });

  final String heading;
  final String? title;
  final String? body;
  final String emptyText;
  final Color color;
  final double rotation;
  final Color pinColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasItem = title != null && title!.trim().isNotEmpty;

    final paper = SizedBox(
      width: 180,
      child: Transform.rotate(
        angle: rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 5),
                    color: Color(0x33000000),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4037),
                        ),
                  ),
                  const SizedBox(height: 6),
                  if (hasItem) ...[
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (body != null && body!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ] else
                    Text(
                      emptyText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      colors: [
                        Color.lerp(pinColor, Colors.white, 0.6)!,
                        pinColor,
                        Color.lerp(pinColor, Colors.black, 0.28)!,
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
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return paper;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: paper,
    );
  }
}