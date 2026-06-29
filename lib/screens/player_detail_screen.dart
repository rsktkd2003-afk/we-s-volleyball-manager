import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/position_fit_service.dart';
import '../widgets/ability_radar_chart.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(player.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: '基本'),
              Tab(text: '身体'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _BasicTab(player: player),
            _PhysicalTab(player: player),
          ],
        ),
      ),
    );
  }
}

class _BasicTab extends StatelessWidget {
  const _BasicTab({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final scores = PositionFitService.calculate(player);
    final bestPosition = PositionFitService.bestPosition(player);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(label: '名前', value: player.name),
        _InfoTile(label: '背番号', value: player.number.toString()),
        _InfoTile(label: 'ポジション', value: player.position),
        _InfoTile(label: '利き手', value: player.dominantHand),
        _InfoTile(label: '学年', value: player.grade),

        const SizedBox(height: 24),

        const Text(
          '能力値レーダー',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AbilityRadarChart(
              values: {
                'スパイク': player.spike,
                'サーブ': player.serve,
                'レセプ': player.reception,
                'ディグ': player.dig,
                'トス': player.toss,
                'ブロック': player.block,
                '機動力': player.mobility,
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'ポジション適性',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '推奨ポジション：$bestPosition',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...scores.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (e.value / 100).clamp(0.0, 1.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(e.value.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhysicalTab extends StatelessWidget {
  const _PhysicalTab({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '身体データ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        _InfoTile(label: '身長', value: '${player.height.toStringAsFixed(1)} cm'),
        _InfoTile(label: '体重', value: '${player.weight.toStringAsFixed(1)} kg'),
        _InfoTile(
          label: '指高',
          value: '${player.standingReach.toStringAsFixed(1)} cm',
        ),
        _InfoTile(
          label: '最高到達点',
          value: '${player.maxReach.toStringAsFixed(1)} cm',
        ),
        _InfoTile(
          label: 'ブロック到達点',
          value: '${player.blockReach.toStringAsFixed(1)} cm',
        ),
        _InfoTile(
          label: 'ジャンプ力',
          value: '${player.jumpHeight.toStringAsFixed(1)} cm',
        ),

        const SizedBox(height: 24),

        const Text(
          '能力パラメーター',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        _InfoTile(label: 'スパイク', value: player.spike.toString()),
        _InfoTile(label: 'サーブ', value: player.serve.toString()),
        _InfoTile(label: 'レセプション', value: player.reception.toString()),
        _InfoTile(label: 'ディグ', value: player.dig.toString()),
        _InfoTile(label: 'トス', value: player.toss.toString()),
        _InfoTile(label: 'ブロック', value: player.block.toString()),
        _InfoTile(label: '機動力', value: player.mobility.toString()),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
