import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import '../utils/player_roles.dart';
import 'pin_badge.dart';

/// 選手一覧グリッドのプレイヤーカード。
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

  /// true の場合、スマホ向けに背番号・名前・ポジション・学年・役職のみを表示する。
  final bool isCompact;

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

  /// 3能力値のうち最も高いものを赤、それ以外を青で強調する。
  Color _barColor(int value) {
    final best = [
      player.spike,
      player.serve,
      player.reception,
    ].reduce((a, b) => a > b ? a : b);
    return value == best * 10 ? AppColors.accent : const Color(0xFF1976D2);
  }

  /// 空文字・'未設定' を未設定として表示する。
  static String _textOrUnset(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '未設定' : trimmed;
  }

  /// 0 以下(未入力)の身体データは数値ではなく「—」で表示する。
  static String _lengthOrDash(double value) {
    return value > 0 ? '${value.toStringAsFixed(0)}cm' : '—';
  }

  @override
  Widget build(BuildContext context) {
    final hasName = player.name.trim().isNotEmpty;
    final grade = _textOrUnset(player.grade);
    final position = _textOrUnset(player.position);

    return Semantics(
      button: true,
      label: '#${player.number} ${hasName ? player.name : '名前未設定'} '
          'の選手カード',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '#${player.number}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isCompact)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent),
                            ),
                            // 狭いカード幅で折り返して縦にはみ出さないよう1行に固定する。
                            child: const Text(
                              'PLAYER CARD',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasName ? player.name : '名前未設定',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.bold,
                        color: hasName
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                            position,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          grade,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        for (final role in player.roles)
                          Tooltip(
                            message: PlayerRoles.displayName(role),
                            child: Icon(
                              PlayerRoles.iconFor(role),
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE0DDD6)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatColumn(
                              label: 'HEIGHT',
                              value: _lengthOrDash(player.height),
                            ),
                          ),
                          Expanded(
                            child: _StatColumn(
                              label: 'REACH',
                              value: _lengthOrDash(player.maxReach),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AbilityBar(
                        label: 'Attack',
                        value: player.spike * 10,
                        color: _barColor(player.spike * 10),
                      ),
                      const SizedBox(height: 4),
                      _AbilityBar(
                        label: 'Serve',
                        value: player.serve * 10,
                        color: _barColor(player.serve * 10),
                      ),
                      const SizedBox(height: 4),
                      _AbilityBar(
                        label: 'Receive',
                        value: player.reception * 10,
                        color: _barColor(player.reception * 10),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: -8,
                left: 20,
                child: PinBadge(color: _pinColor, size: 16),
              ),
            ],
          ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
