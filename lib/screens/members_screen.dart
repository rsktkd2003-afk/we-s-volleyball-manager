import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/add_player_dialog.dart';
import '../models/player.dart';
import '../providers/player_providers.dart';
import '../theme/app_colors.dart';
import '../utils/firestore_collections.dart';
import '../widgets/player_filter_bar.dart';
import '../widgets/player_list.dart';
import 'player_detail_screen.dart';
import 'player_edit_screen.dart';

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

    final newPlayer = Player(
      name: name.trim(),
      number: 0,
      position: '未設定',
      dominantHand: '右',
      grade: '未設定',
      height: 0.0,
      weight: 0.0,
      standingReach: 0.0,
      maxReach: 0.0,
      blockReach: 0.0,
    );

    await FirebaseFirestore.instance
        .collection(FirestoreCollections.players)
        .add({
      ...newPlayer.toJson(),
      'ownerUid': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  Future<void> openPlayerDetail(Player player) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailScreen(player: player),
      ),
    );
    if (!mounted) return;

    if (result == 'delete') {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.players)
          .doc(player.id)
          .delete();
      return;
    }

    if (result == 'edit') {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerEditScreen(player: player),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return Container(
      color: AppColors.boardBackground,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "WE'S VOLLEYBALL CLUB",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'PLAYER SCOUTING BOARD',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(width: 56, height: 4, color: AppColors.accent),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  final filterPanel = PlayerFilterBar(
                    searchQuery: searchQuery,
                    grade: selectedGrade,
                    position: selectedPosition,
                    sortType: sortType,
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
                    data: (players) => PlayerList(
                      players: getFilteredPlayers(players),
                      onTap: openPlayerDetail,
                      onAddPlayer: addPlayer,
                    ),
                    loading: () => const _PlayersLoading(),
                    error: (error, _) {
                      debugPrint('MembersScreen players stream error: $error');
                      return _PlayersError(
                        error: error,
                        onRetry: () => ref.invalidate(playersProvider),
                      );
                    },
                  );

                  if (!isWide) {
                    return Column(
                      children: [
                        filterPanel,
                        const SizedBox(height: 20),
                        grid,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: grid),
                      const SizedBox(width: 20),
                      SizedBox(width: 260, child: filterPanel),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayersLoading extends StatelessWidget {
  const _PlayersLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
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
      child: Column(
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
    );
  }
}
