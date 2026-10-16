import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../providers/player_providers.dart';
import '../services/position_fit_service.dart';
import '../theme/app_colors.dart';
import '../utils/player_operation_errors.dart';
import '../utils/player_roles.dart';
import '../widgets/ability_radar_chart.dart';
import '../widgets/masking_tape.dart';
import '../widgets/pin_badge.dart';
import '../widgets/player_issue_section.dart';
import 'player_edit_screen.dart';

part 'player_detail_screen_layout.dart';
part 'player_detail_screen_cards.dart';
part 'player_detail_screen_chrome.dart';

/// 選手詳細画面から呼び出し元(一覧)へ返す結果。
enum PlayerDetailResult {
  /// 選手を削除した。
  deleted,
}

/// 選手詳細。編集・削除はこの画面で完結させる。
/// - 編集: 編集画面で保存に成功した内容で表示を更新する。
/// - 削除: 確認後に削除し、成功時のみ [PlayerDetailResult.deleted] を返して閉じる。
class PlayerDetailScreen extends ConsumerStatefulWidget {
  const PlayerDetailScreen({super.key, required this.player});

  final Player player;

  @override
  ConsumerState<PlayerDetailScreen> createState() =>
      _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {
  static const Color _accentRed = Color(0xFFC0392B);
  static const Color _boardColor = Color(0xFFE9E8E3);

  /// 一覧から受け取った選手、または編集の保存に成功した内容。
  /// 最新データ([playersProvider])が得られない場合の表示に使う。
  late Player _player = widget.player;

  /// 削除処理中か。この画面での二重実行と、処理中の編集を防ぐ。
  /// 削除中でも画面は離れられる(書き込みは取り消せず、オフライン時は
  /// 通信回復まで完了しないため、画面に閉じ込めない)。
  bool _deleting = false;

  /// 表示する選手。一覧と共有している players の購読に最新データがあれば
  /// それを優先する(他の端末での連携情報の変更なども反映される)。
  /// 追加の Firestore 読み取りは発生しない。
  Player _latest(List<Player>? players) {
    if (players == null || _player.id.isEmpty) return _player;
    for (final player in players) {
      if (player.id == _player.id) return player;
    }
    return _player;
  }

  Player get _currentPlayer =>
      _latest(ref.read(playersProvider).valueOrNull);

  static String _nameOf(Player player) =>
      player.name.trim().isEmpty ? '名前未設定' : player.name;

  /// 前のメッセージが残っていると新しい結果の通知が遅れるため、置き換えて表示する。
  /// 通知先が破棄済み(ログアウト等)なら何もしない。
  static void _showMessage(ScaffoldMessengerState messenger, String message) {
    if (!messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (!didPop || !_deleting) return;
    // 結果は未確定のため、成功・失敗は断定しない。
    _showMessage(
      ScaffoldMessenger.of(context),
      '削除処理を続けています。完了または失敗したときにお知らせします。',
    );
  }

  Future<void> _openEditor() async {
    if (_deleting) return;

    final updated = await Navigator.push<Player>(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerEditScreen(player: _currentPlayer),
      ),
    );

    // キャンセル時、または保存中に編集画面を離れた場合(null)は
    // 保存済みと断定せず、元の表示(と最新データ)を維持する。
    if (!mounted || updated == null) return;
    setState(() => _player = updated);
    _showMessage(ScaffoldMessenger.of(context), '選手データを保存しました');
  }

  Future<void> _confirmAndDelete() async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          title: const Text('選手を削除しますか？'),
          content: Text('「${_nameOf(_currentPlayer)}」を削除します。この操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _accentRed),
              child: const Text('削除する'),
            ),
          ],
        );
      },
    );

    // 確認ダイアログ表示中の二重タップも、ここで1回に絞られる。
    if (confirmed != true || !mounted || _deleting) return;

    // 画面を離れた後でも結果を通知できるよう、アプリ共通の通知先を控える。
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameOf(_currentPlayer);

    setState(() => _deleting = true);

    try {
      await ref.read(playerRepositoryProvider).deletePlayer(_player.id);
    } catch (error) {
      debugPrint('PlayerDetailScreen delete error: $error');
      final message = playerOperationErrorMessage(error, action: '削除');
      if (mounted) {
        // 削除済みとして扱わず、詳細画面に留まって再試行できるようにする。
        setState(() => _deleting = false);
        _showMessage(messenger, message);
      } else {
        _showMessage(messenger, '「$name」の$message');
      }
      return;
    }

    if (mounted) {
      // 完了して自ら閉じるため、「処理を続けています」の通知を出さない。
      _deleting = false;
      Navigator.pop(context, PlayerDetailResult.deleted);
    } else {
      // 削除中に詳細画面を離れていた場合は、完了をここで伝える。
      _showMessage(messenger, '「$name」を削除しました');
    }
  }

  /// 編集・削除の導線。幅に余裕がある場合は文字ラベル付きで表示する。
  /// 削除処理中は両方とも押せないようにし、削除ボタンに進行状態を出す。
  List<Widget> _buildActions({required bool showLabels}) {
    final onEdit = _deleting ? null : _openEditor;
    return [
      IconButton(
        tooltip: '編集',
        icon: const Icon(Icons.edit_outlined),
        color: AppColors.action,
        onPressed: onEdit,
      ),
      PopupMenuButton<String>(
        tooltip: 'その他の操作',
        enabled: !_deleting,
        onSelected: (_) => _confirmAndDelete(),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Text('選手を削除', style: TextStyle(color: _accentRed)),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final player = _latest(ref.watch(playersProvider).valueOrNull);
    final displayName = _nameOf(player);

    return PopScope(
      onPopInvokedWithResult: _onPopInvoked,
      child: LayoutBuilder(
        builder: (context, constraints) => DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: _boardColor,
            appBar: AppBar(
              title: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: const Color(0xFFF7F5EF),
              foregroundColor: const Color(0xFF252525),
              elevation: 1,
              actions: _buildActions(showLabels: constraints.maxWidth >= 600),
              bottom: const TabBar(
                labelColor: _accentRed,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: _accentRed,
                tabs: [
                  Tab(icon: Icon(Icons.badge_outlined), text: 'スカウトカード'),
                  Tab(icon: Icon(Icons.flag_outlined), text: '改善点'),
                ],
              ),
            ),
            body: Column(
              children: [
                if (_deleting) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const _DeletingNotice(),
                ],
                Expanded(
                  child: TabBarView(
                    children: [
                      // 編集後に表示を確実に作り直すため、内容でキーを変える。
                      _ScoutingBoard(key: ObjectKey(player), player: player),
                      PlayerIssueSection(player: player),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 削除中の説明。結果が出るまで成功・失敗は断定しない。
class _DeletingNotice extends StatelessWidget {
  const _DeletingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        '削除しています。通信状態によっては時間がかかります。'
        'この画面を離れても処理は続き、完了または失敗したときにお知らせします。',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
    );
  }
}

class _ScoutingBoard extends StatelessWidget {
  const _ScoutingBoard({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 700;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE9E8E3),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1F0EC), Color(0xFFE1E0DC)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(top: 10, left: 10, child: _BoardScrew()),
              const Positioned(top: 10, right: 10, child: _BoardScrew()),
              const Positioned(bottom: 10, left: 10, child: _BoardScrew()),
              const Positioned(bottom: 10, right: 10, child: _BoardScrew()),
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 34 : 16,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: isDesktop
                        ? _DesktopLayout(player: player)
                        : _CompactLayout(player: player, isTablet: isTablet),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
