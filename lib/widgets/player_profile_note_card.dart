import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import 'pin_badge.dart';

/// 掲示板に貼られた縦型プロフィールカード（グリッドセルいっぱいに広がる）。
class PlayerProfileNoteCard extends StatelessWidget {
  const PlayerProfileNoteCard({
    super.key,
    required this.player,
    required this.seed,
    required this.onTap,
  });

  final Player player;
  final int seed;
  final VoidCallback onTap;

  static const List<double> _angles = [-0.05, -0.03, 0.0, 0.03, 0.05];

  double get _overall {
    final sum = player.spike +
        player.serve +
        player.reception +
        player.dig +
        player.toss +
        player.block +
        player.mobility;
    return sum / 7;
  }

  @override
  Widget build(BuildContext context) {
    final angle = _angles[seed.abs() % _angles.length];

    return Transform.rotate(
      angle: angle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Ink(
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      offset: Offset(0, 6),
                      color: Color(0x3A000000),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${player.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${player.position} ・ ${player.height.toStringAsFixed(0)}cm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 18,
                            color: Color(0xFFF9A825),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '総合 ${_overall.toStringAsFixed(1)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: PinBadge(
                    seed: seed,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}