import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../providers/player_providers.dart';
import '../utils/player_edit_input.dart';
import '../utils/player_operation_errors.dart';
import '../utils/player_roles.dart';

/// 選手編集画面。保存に成功した場合のみ、保存した [Player] を返して閉じる。
/// キャンセル(戻る)した場合は null を返す。
class PlayerEditScreen extends ConsumerStatefulWidget {
  const PlayerEditScreen({super.key, required this.player});

  final Player player;

  @override
  ConsumerState<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends ConsumerState<PlayerEditScreen> {
  /// 保存処理中か。この画面での二重実行の防止に使う。
  /// 保存中でも画面は離れられる(Firestoreの書き込みは取り消せず、
  /// オフライン時は通信回復まで完了しないため、画面に閉じ込めない)。
  bool _saving = false;

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

  Future<void> savePlayer() async {
    if (_saving) return;

    final updatedPlayer = playerFromEditInput(
      original: widget.player,
      name: nameController.text,
      number: numberController.text,
      position: positionController.text,
      dominantHand: dominantHandController.text,
      grade: gradeController.text,
      height: heightController.text,
      weight: weightController.text,
      standingReach: standingReachController.text,
      maxReach: maxReachController.text,
      blockReach: blockReachController.text,
      spike: spikeController.text,
      serve: serveController.text,
      reception: receptionController.text,
      dig: digController.text,
      toss: tossController.text,
      block: blockController.text,
      mobility: mobilityController.text,
      roles: selectedRoles.toList(),
    );

    // 画面を離れた後でも結果を通知できるよう、アプリ共通の通知先を控える。
    final messenger = ScaffoldMessenger.of(context);
    final displayName = updatedPlayer.name.isEmpty
        ? '名前未設定'
        : updatedPlayer.name;

    setState(() => _saving = true);

    try {
      // 編集できる項目だけを書き込み、連携情報などは上書きしない。
      await ref
          .read(playerRepositoryProvider)
          .updateEditableFields(updatedPlayer);
    } catch (error) {
      debugPrint('PlayerEditScreen save error: $error');
      final message = playerOperationErrorMessage(error, action: '保存');

      if (mounted) {
        // 入力内容はそのまま残し、再度保存できるようにする。
        setState(() => _saving = false);
        _showSnackBar(messenger, message);
      } else {
        // 保存中に画面を離れていた場合も、失敗したことを伝える。
        _showSnackBar(messenger, '「$displayName」の$message');
      }
      return;
    }

    if (mounted) {
      // 保存成功時のみ、保存した内容を詳細画面へ返す。
      // 完了して自ら閉じるため、「処理を続けています」の通知を出さない。
      _saving = false;
      Navigator.pop(context, updatedPlayer);
    } else {
      // 保存中に画面を離れていた場合は、完了をここで伝える。
      _showSnackBar(messenger, '「$displayName」の保存が完了しました');
    }
  }

  /// 通知先が破棄済み(ログアウト等)なら何もしない。
  static void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    if (!messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (!didPop || !_saving) return;
    // 結果は未確定のため、成功・失敗は断定しない。
    _showSnackBar(
      ScaffoldMessenger.of(context),
      '保存処理を続けています。完了または失敗したときにお知らせします。',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('選手編集'),
          actions: [
            IconButton(
              tooltip: '保存',
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: _saving ? null : savePlayer,
            ),
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
            _TextField(
              controller: numberController,
              label: '背番号',
              keyboardType: TextInputType.number,
            ),
            _TextField(controller: positionController, label: 'ポジション'),
            _TextField(controller: dominantHandController, label: '利き手'),
            _TextField(controller: gradeController, label: '学年'),

            const SizedBox(height: 24),

            const Text(
              '身体データ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _TextField(
              controller: heightController,
              label: '身長 cm',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _TextField(
              controller: weightController,
              label: '体重 kg',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _TextField(
              controller: standingReachController,
              label: '指高 cm',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _TextField(
              controller: maxReachController,
              label: '最高到達点 cm',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _TextField(
              controller: blockReachController,
              label: 'ブロック到達点 cm',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '能力値（1〜10）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _TextField(
              controller: spikeController,
              label: 'スパイク',
              keyboardType: TextInputType.number,
            ),
            _TextField(
              controller: serveController,
              label: 'サーブ',
              keyboardType: TextInputType.number,
            ),
            _TextField(
              controller: receptionController,
              label: 'レセプション',
              keyboardType: TextInputType.number,
            ),
            _TextField(
              controller: digController,
              label: 'ディグ',
              keyboardType: TextInputType.number,
            ),
            _TextField(
              controller: tossController,
              label: 'トス',
              keyboardType: TextInputType.number,
            ),
            _TextField(
              controller: blockController,
              label: 'ブロック',
              keyboardType: TextInputType.number,
            ),
            _TextField(
              controller: mobilityController,
              label: '機動力',
              keyboardType: TextInputType.number,
            ),

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

            if (_saving) ...[
              const _PendingNotice(),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _saving ? null : savePlayer,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? '保存中...' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 保存中の説明。結果が出るまで成功・失敗は断定しない。
class _PendingNotice extends StatelessWidget {
  const _PendingNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '保存しています。通信状態によっては時間がかかります。'
      'この画面を離れても処理は続き、完了または失敗したときにお知らせします。',
      style: TextStyle(fontSize: 13, height: 1.5),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
