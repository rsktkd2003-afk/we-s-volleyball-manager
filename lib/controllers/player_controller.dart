import 'package:flutter/material.dart';

import '../dialogs/add_player_dialog.dart';
import '../models/player.dart';
import '../screens/player_detail_screen.dart';

class PlayerController {
  PlayerController({
    required this.context,
    required this.players,
    required this.onChanged,
    required this.onSave,
  });

  final BuildContext context;
  final List<Player> players;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

  Future<void> addPlayer() async {
    final name = await showAddPlayerDialog(context);

    if (name == null || name.trim().isEmpty) {
      return;
    }

    players.add(
      Player(
        name: name.trim(),
        position: 'Unknown',
        height: 0,
        standingReach: 0,
        maxReach: 0,
      ),
    );

    onChanged();
    await onSave();
  }

  Future<void> openPlayerDetail(Player player) async {
    final shouldDelete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailScreen(player: player),
      ),
    );

    if (shouldDelete == true) {
      players.remove(player);
    }

    onChanged();
    await onSave();
  }
}