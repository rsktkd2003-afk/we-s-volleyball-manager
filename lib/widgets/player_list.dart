import 'package:flutter/material.dart';

import '../models/player.dart';
import 'player_profile_note_card.dart';

class PlayerList extends StatelessWidget {
  final List<Player> players;
  final void Function(Player player) onTap;

  const PlayerList({super.key, required this.players, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,

        // 0.85: さらに縦長でカード面積が大きく見える
        // 0.90: 正方形すぎず、今回のプロフィールカードに一番合いやすい
        // 1.00: 現在に近い正方形。一覧性重視
        childAspectRatio: 0.82,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) {
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