import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/add_player_dialog.dart';
import '../models/player.dart';
import '../providers/player_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/player_filter_bar.dart';
import '../widgets/club_board_placeholder.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/player_list.dart';
import 'player_detail_screen.dart';

/// メンバータブ。既存の PLAYER SCOUTING BOARD (選手一覧・検索・追加・
/// 詳細・編集・削除) を表示する。
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String searchQuery = '';
  String selectedGrade = '全員';
  String selectedPosition = '全員';
  String sortType = '背番号';

  /// スマホ幅で絞り込み条件を開いているか(タブ切り替え後も保持する)。
  bool filtersExpanded = false;

  List<Player> getFilteredPlayers(List<Player> players) {
    List<Player> result = [...players];

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    }

    if (selectedGrade != '全員') {
      result = result.where((p) => p.grade == selectedGrade).toList();
    }

    if (selectedPosition != '全員') {
      result = result.where((p) => p.position == selectedPosition).toList();
    }

    switch (sortType) {
      case '背番号':
        result.sort((a, b) => a.number.compareTo(b.number));
      case '学年':
        result.sort((a, b) => a.grade.compareTo(b.grade));
      case '名前':
        result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  Future<void> addPlayer() async {
    final name = await showAddPlayerDialog(context);
    if (!mounted) return;

    if (name == null || name.trim().isEmpty) return;

    await ref.read(playerRepositoryProvider).addPlayer(name.trim());
  }

  /// 選手詳細を開く。編集・削除(確認・エラー処理を含む)は詳細画面で行い、
  /// 削除に成功した場合のみ一覧へ戻って完了を通知する。
  Future<void> openPlayerDetail(Player player) async {
    final result = await Navigator.push<PlayerDetailResult>(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailScreen(player: player),
      ),
    );
    if (!mounted) return;

    if (result == PlayerDetailResult.deleted) {
      final name = player.name.trim().isEmpty ? '名前未設定' : player.name;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('「$name」を削除しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return CorkBoardBackground(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // 一覧幅に応じて絞り込みの配置を切り替える。
                  final filterLayout = width >= 900
                      ? PlayerFilterLayout.panel
                      : width >= 600
                          ? PlayerFilterLayout.inline
                          : PlayerFilterLayout.compact;

                  final filterPanel = PlayerFilterBar(
                    searchQuery: searchQuery,
                    grade: selectedGrade,
                    position: selectedPosition,
                    sortType: sortType,
                    layout: filterLayout,
                    expanded: filtersExpanded,
                    onExpandedChanged: (value) =>
                        setState(() => filtersExpanded = value),
                    onSearchChanged: (value) =>
                        setState(() => searchQuery = value),
                    onGradeChanged: (value) =>
                        setState(() => selectedGrade = value),
                    onPositionChanged: (value) =>
                        setState(() => selectedPosition = value),
                    onSortChanged: (value) =>
                        setState(() => sortType = value),
                  );

                  final grid = playersAsync.when(
                    data: (players) {
                      final filtered = getFilteredPlayers(players);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ResultCountLabel(
                            shown: filtered.length,
                            total: players.length,
                          ),
                          const SizedBox(height: 12),
                          PlayerList(
                            players: filtered,
                            onTap: openPlayerDetail,
                            onAddPlayer: addPlayer,
                          ),
                        ],
                      );
                    },
                    loading: () => const _PlayersLoading(),
                    error: (error, _) {
                      debugPrint('MembersScreen players stream error: $error');
                      return _PlayersError(
                        error: error,
                        onRetry: () => ref.invalidate(playersProvider),
                      );
                    },
                  );

                  const heading = ClubBoardHeading(
                    title: 'PLAYER SCOUTING BOARD',
                  );

                  if (filterLayout != PlayerFilterLayout.panel) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading,
                        const SizedBox(height: 12),
                        filterPanel,
                        const SizedBox(height: 12),
                        grid,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: grid),
                          const SizedBox(width: 20),
                          SizedBox(width: 260, child: filterPanel),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 絞り込み結果の件数を紙のラベルで表示する。
class _ResultCountLabel extends StatelessWidget {
  const _ResultCountLabel({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = shown == total ? '$total名' : '$shown名を表示中 / 全$total名';

    return _PaperLabel(
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// コルク地の上で文字を読みやすくするための小さな紙。
class _PaperLabel extends StatelessWidget {
  const _PaperLabel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 2),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlayersLoading extends StatelessWidget {
  const _PlayersLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: _PaperLabel(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _PlayersError extends StatelessWidget {
  const _PlayersError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: _PaperLabel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '選手データの取得に失敗しました: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}
