import 'package:flutter/material.dart';

import '../../../models/player.dart';
import '../../../services/firestore_service.dart';

class PlayerLinkScreen extends StatefulWidget {
  const PlayerLinkScreen({super.key});

  @override
  State<PlayerLinkScreen> createState() => _PlayerLinkScreenState();
}

class _PlayerLinkScreenState extends State<PlayerLinkScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List<Player> players = [];
  Player? selectedPlayer;
  String? message;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      message = null;
      errorMessage = null;
    });

    try {
      final pending = await FirestoreService.loadMyPendingPlayerLinkRequest();

      if (pending != null) {
        setState(() {
          message = '現在、${pending.playerName} への連携申請中です。管理者の承認を待ってください。';
          players = [];
          selectedPlayer = null;
          isLoading = false;
        });
        return;
      }

      final loadedPlayers = await FirestoreService.loadUnlinkedPlayers();

      setState(() {
        players = loadedPlayers;
        selectedPlayer = loadedPlayers.isNotEmpty ? loadedPlayers.first : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '読み込みに失敗しました: $e';
        isLoading = false;
      });
    }
  }

  Future<void> submitRequest() async {
    final player = selectedPlayer;
    if (player == null) {
      setState(() {
        errorMessage = '選手を選択してください';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      message = null;
      errorMessage = null;
    });

    try {
      await FirestoreService.createPlayerLinkRequest(
        playerId: player.id,
        playerName: player.name,
      );

      setState(() {
        message = '${player.name} への連携申請を送信しました。管理者の承認を待ってください。';
        players = [];
        selectedPlayer = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = '申請に失敗しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選手データ連携'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 520,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '選手データを連携してください',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '自分の名前を選んで連携申請してください。管理者が承認すると、出欠入力などが使えるようになります。',
                      ),
                      const SizedBox(height: 24),
                      if (message != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      if (errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (message != null || errorMessage != null)
                        const SizedBox(height: 16),
                      if (players.isEmpty && message == null)
                        const Text('連携できる未連携の選手データがありません。'),
                      if (players.isNotEmpty)
                        Expanded(
                          child: RadioGroup<Player?>(
                            groupValue: selectedPlayer,
                            onChanged: (Player? value) {
                              if (isSubmitting) return;

                              setState(() {
                                selectedPlayer = value;
                              });
                            },
                            child: ListView.separated(
                              itemCount: players.length,
                              separatorBuilder: (_, _) => const Divider(),
                              itemBuilder: (context, index) {
                                final player = players[index];
                                final selected =
                                    selectedPlayer?.id == player.id;

                                return RadioListTile<Player?>(
                                  value: player,
                                  title: Text(
                                    '${player.number}  ${player.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${player.position} / ${player.grade}',
                                  ),
                                  selected: selected,
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (players.isNotEmpty)
                        ElevatedButton(
                          onPressed: isSubmitting ? null : submitRequest,
                          child: Text(isSubmitting ? '申請中...' : '連携申請する'),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}