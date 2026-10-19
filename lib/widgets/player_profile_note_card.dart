import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_colors.dart';
import '../utils/player_roles.dart';

/// Compact horizontal roster card. Detailed stats remain in player details.
class PlayerProfileNoteCard extends StatelessWidget {
  const PlayerProfileNoteCard({
    super.key,
    required this.player,
    required this.seed,
    required this.onTap,
    this.isCompact = false,
  });
  final Player player;
  final int seed;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE1DDD5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${player.number}',
                  style: const TextStyle(
                    color: AppColors.action,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.name.trim().isEmpty ? '名前未設定' : player.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          player.position.isEmpty ? '未設定' : player.position,
                          style: const TextStyle(
                            color: AppColors.action,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          player.grade.isEmpty ? '未設定' : player.grade,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        for (final role in player.roles)
                          Tooltip(
                            message: PlayerRoles.displayName(role),
                            child: Icon(
                              PlayerRoles.iconFor(role),
                              size: 16,
                              color: AppColors.action,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.action),
            ],
          ),
        ),
      ),
    );
  }
}
