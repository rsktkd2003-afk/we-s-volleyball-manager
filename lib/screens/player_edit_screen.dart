import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';
import '../utils/firestore_collections.dart';
import '../utils/player_roles.dart';

class PlayerEditScreen extends StatefulWidget {
  const PlayerEditScreen({super.key, required this.player});

  final Player player;

  @override
  State<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends State<PlayerEditScreen> {
  late final TextEditingController nameController;
  late final TextEditingController numberController;
  late final TextEditingController positionController;
  late final TextEditingController dominantHandController;
  late final TextEditingController gradeController;

  late final TextEditingController heightController;
  late final TextEditingController weightController;
  late final TextEditingController standingReachController;
  late final TextEditingController maxReachController;
  late final TextEditingController blockReachController;

  late final TextEditingController spikeController;
  late final TextEditingController serveController;
  late final TextEditingController receptionController;
  late final TextEditingController digController;
  late final TextEditingController tossController;
  late final TextEditingController blockController;
  late final TextEditingController mobilityController;

  late Set<String> selectedRoles;

  @override
  void initState() {
    super.initState();

    final player = widget.player;

    selectedRoles = Set<String>.from(player.roles);

    nameController = TextEditingController(text: player.name);
    numberController = TextEditingController(text: player.number.toString());
    positionController = TextEditingController(text: player.position);
    dominantHandController = TextEditingController(text: player.dominantHand);
    gradeController = TextEditingController(text: player.grade);

    heightController = TextEditingController(
      text: player.height.toStringAsFixed(1),
    );
    weightController = TextEditingController(
      text: player.weight.toStringAsFixed(1),
    );
    standingReachController = TextEditingController(
      text: player.standingReach.toStringAsFixed(1),
    );
    maxReachController = TextEditingController(
      text: player.maxReach.toStringAsFixed(1),
    );
    blockReachController = TextEditingController(
      text: player.blockReach.toStringAsFixed(1),
    );

    spikeController = TextEditingController(text: player.spike.toString());
    serveController = TextEditingController(text: player.serve.toString());
    receptionController = TextEditingController(
      text: player.reception.toString(),
    );
    digController = TextEditingController(text: player.dig.toString());
    tossController = TextEditingController(text: player.toss.toString());
    blockController = TextEditingController(text: player.block.toString());
    mobilityController = TextEditingController(
      text: player.mobility.toString(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    positionController.dispose();
    dominantHandController.dispose();
    gradeController.dispose();

    heightController.dispose();
    weightController.dispose();
    standingReachController.dispose();
    maxReachController.dispose();
    blockReachController.dispose();

    spikeController.dispose();
    serveController.dispose();
    receptionController.dispose();
    digController.dispose();
    tossController.dispose();
    blockController.dispose();
    mobilityController.dispose();

    super.dispose();
  }

  double _toDouble(String value) {
    return double.tryParse(value) ?? 0.0;
  }

  int _toInt(String value) {
    return int.tryParse(value) ?? 0;
  }

  int _toAbility(String value) {
    final parsed = int.tryParse(value) ?? 5;
    return parsed.clamp(1, 10);
  }

  Future<void> savePlayer() async {
  final updatedPlayer = Player(
    id: widget.player.id,

    // 既存情報を保持
    ownerUid: widget.player.ownerUid,
    linkedUid: widget.player.linkedUid,

    // 基本情報
    name: nameController.text.trim(),
    number: _toInt(numberController.text),
    position: positionController.text.trim(),
    dominantHand: dominantHandController.text.trim(),
    grade: gradeController.text.trim(),

    // 身体データ
    height: _toDouble(heightController.text),
    weight: _toDouble(weightController.text),
    standingReach: _toDouble(standingReachController.text),
    maxReach: _toDouble(maxReachController.text),
    blockReach: _toDouble(blockReachController.text),

    // 能力値
    spike: _toAbility(spikeController.text),
    serve: _toAbility(serveController.text),
    reception: _toAbility(receptionController.text),
    dig: _toAbility(digController.text),
    toss: _toAbility(tossController.text),
    block: _toAbility(blockController.text),
    mobility: _toAbility(mobilityController.text),

    // 編集対象ではないパラメータを保持
    jump: widget.player.jump,
    power: widget.player.power,
    speed: widget.player.speed,
    stamina: widget.player.stamina,
    gameSense: widget.player.gameSense,

    // 役職
    roles: selectedRoles.toList(),
  );

  await FirebaseFirestore.instance
      .collection(FirestoreCollections.players)
      .doc(updatedPlayer.id)
      .update(updatedPlayer.toJson());

  if (!mounted) return;
  Navigator.pop(context, true);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選手編集'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: savePlayer),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '基本プロフィール',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _TextField(controller: nameController, label: '名前'),
          _TextField(controller: numberController, label: '背番号'),
          _TextField(controller: positionController, label: 'ポジション'),
          _TextField(controller: dominantHandController, label: '利き手'),
          _TextField(controller: gradeController, label: '学年'),

          const SizedBox(height: 24),

          const Text(
            '身体データ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _TextField(controller: heightController, label: '身長 cm'),
          _TextField(controller: weightController, label: '体重 kg'),
          _TextField(controller: standingReachController, label: '指高 cm'),
          _TextField(controller: maxReachController, label: '最高到達点 cm'),
          _TextField(controller: blockReachController, label: 'ブロック到達点 cm'),

          const SizedBox(height: 24),

          const Text(
            '能力値（1〜10）',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _TextField(controller: spikeController, label: 'スパイク'),
          _TextField(controller: serveController, label: 'サーブ'),
          _TextField(controller: receptionController, label: 'レセプション'),
          _TextField(controller: digController, label: 'ディグ'),
          _TextField(controller: tossController, label: 'トス'),
          _TextField(controller: blockController, label: 'ブロック'),
          _TextField(controller: mobilityController, label: '機動力'),

          const SizedBox(height: 24),

          const Text(
            '役職（複数選択可）',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (final role in PlayerRoles.all)
            CheckboxListTile(
              value: selectedRoles.contains(role),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              secondary: Icon(PlayerRoles.iconFor(role), size: 20),
              title: Text(PlayerRoles.displayName(role)),
              onChanged: (selected) {
                setState(() {
                  if (selected ?? false) {
                    selectedRoles.add(role);
                  } else {
                    selectedRoles.remove(role);
                  }
                });
              },
            ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: savePlayer,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
