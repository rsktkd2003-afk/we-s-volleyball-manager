import 'package:flutter/material.dart';

import '../models/player.dart';
import 'new_player_card.dart';
import 'player_profile_note_card.dart';

class PlayerList extends StatelessWidget {
  final List<Player> players;
  final void Function(Player player) onTap;
  final VoidCallback onAddPlayer;

  const PlayerList({
    super.key,
    required this.players,
    required this.onTap,
    required this.onAddPlayer,
  });

  /// この幅未満はスマホ表示（カード内の情報を絞る）。
  static const double _mobileBreakpoint = 600;

  /// 詳細表示カードの目安の幅。一覧幅からこの幅を基準に列数を決める。
  static const double _targetCardWidth = 240;

  static const double _spacing = 14;

  /// カード上端のピンが前の行のカードに重ならないよう、行間を広めに取る。
  static const double _runSpacing = 24;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < _mobileBreakpoint;

        // スマホ幅は2列(極端に狭い幅は1列)、それ以上はカード幅の目安から
        // 列数を決める。カードの高さは内容に合わせるため、長い名前や
        // 文字サイズの拡大でもカードからはみ出さない。
        final columns = isCompact
            ? (width >= 300 ? 2 : 1)
            : ((width + _spacing) / (_targetCardWidth + _spacing))
                .floor()
                .clamp(2, 5);
        final cardWidth = (width - _spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: _spacing,
          runSpacing: _runSpacing,
          children: [
            for (var index = 0; index < players.length; index++)
              SizedBox(
                width: cardWidth,
                child: PlayerProfileNoteCard(
                  player: players[index],
                  // id があれば id、無ければ index を seed に（決定的）
                  seed: players[index].id.isNotEmpty
                      ? players[index].id.hashCode
                      : index,
                  isCompact: isCompact,
                  onTap: () => onTap(players[index]),
                ),
              ),
            SizedBox(
              width: cardWidth,
              height: isCompact ? 132 : 200,
              child: NewPlayerCard(onTap: onAddPlayer),
            ),
          ],
        );
      },
    );
  }
}
