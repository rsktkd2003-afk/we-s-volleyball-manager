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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _mobileBreakpoint;

        // スマホ幅: カード最大幅を基準に列数を自動決定（無理な3列固定を避ける）。
        // 通常のスマホ幅では2列、非常に狭い幅では自動的に1列になる。
        final gridDelegate = isCompact
            ? const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              )
            : const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.78,
              );

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: gridDelegate,
          itemCount: players.length + 1,
          itemBuilder: (context, index) {
            if (index == players.length) {
              return NewPlayerCard(onTap: onAddPlayer);
            }

            final player = players[index];

            // id があれば id、無ければ index を seed に（決定的）
            final seed = player.id.isNotEmpty ? player.id.hashCode : index;

            return PlayerProfileNoteCard(
              player: player,
              seed: seed,
              isCompact: isCompact,
              onTap: () => onTap(player),
            );
          },
        );
      },
    );
  }
}
