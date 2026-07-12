import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bulletin_providers.dart';
import '../theme/app_colors.dart';

/// お知らせ(既存のannouncementsProvider)を箇条書きでまとめて表示するMEMO付箋。
class ScheduleMemoNote extends ConsumerWidget {
  const ScheduleMemoNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    final lines = announcementsAsync.maybeWhen(
      data: (items) => items.take(5).map((a) => '・${a.title}').toList(),
      orElse: () => const <String>[],
    );

    return Transform.rotate(
      angle: -0.015,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3B0),
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
                const Text(
                  'MEMO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 8),
                if (lines.isEmpty)
                  const Text(
                    'お知らせはまだありません',
                    style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
                  )
                else
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.3),
                    colors: [
                      Color(0xFFF5A6A6),
                      AppColors.accent,
                      Color(0xFF7A1010),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
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
    );
  }
}
