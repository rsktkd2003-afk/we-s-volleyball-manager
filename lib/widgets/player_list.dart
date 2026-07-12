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

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.78,
      ),
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
          onTap: () => onTap(player),
        );
      },
    );
  }
}