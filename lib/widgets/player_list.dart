import 'package:flutter/material.dart';

import '../models/player.dart';

class PlayerList extends StatelessWidget {
  final List<Player> players;
  final void Function(Player player) onTap;

  const PlayerList({
    super.key,
    required this.players,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];

        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(player.name),
          subtitle: Text(
            '${player.position} | ${player.height}cm',
          ),
          onTap: () => onTap(player),
        );
      },
    );
  }
}