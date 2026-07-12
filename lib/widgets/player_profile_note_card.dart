import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import '../utils/player_roles.dart';

/// 選手一覧グリッドのプレイヤーカード。
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

  static const List<Color> _pinPalette = [
    AppColors.accent,
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFF7B1FA2),
  ];

  static const Map<String, Color> _positionColors = {
    'S': Color(0xFF388E3C),
    'MB': Color(0xFF1976D2),
    'OP': Color(0xFFF9A825),
    'L': Color(0xFF7B1FA2),
    'WS': AppColors.accent,
    'OH': AppColors.accent,
  };

  Color get _pinColor => _pinPalette[seed.abs() % _pinPalette.length];

  Color get _positionColor =>
      _positionColors[player.position] ?? const Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -14,
              left: 22,
              child: Transform.rotate(
                angle: -0.35,
                child: Icon(
                  Icons.push_pin,
                  size: 20,
                  color: _pinColor,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Color(0x26000000),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${player.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: const Text(
                              'PLAYER CARD',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          if (player.roles.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final role in player.roles)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Tooltip(
                                      message: PlayerRoles.displayName(role),
                                      child: Icon(
                                        PlayerRoles.iconFor(role),
                                        size: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _positionColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          player.position,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        player.grade,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE0DDD6)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          label: 'HEIGHT',
                          value: '${player.height.toStringAsFixed(0)}cm',
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          label: 'REACH',
                          value: '${player.maxReach.toStringAsFixed(0)}cm',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AbilityBar(
                    label: 'Attack',
                    value: player.spike * 10,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 4),
                  _AbilityBar(
                    label: 'Serve',
                    value: player.serve * 10,
                    color: const Color(0xFF1976D2),
                  ),
                  const SizedBox(height: 4),
                  _AbilityBar(
                    label: 'Receive',
                    value: player.reception * 10,
                    color: const Color(0xFF388E3C),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _AbilityBar extends StatelessWidget {
  const _AbilityBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE7E4DE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
