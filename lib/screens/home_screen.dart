import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dialogs/add_player_dialog.dart';
import '../models/player.dart';
import '../utils/firestore_collections.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/player_filter_bar.dart';
import '../widgets/player_list.dart';
import '../widgets/wes_app_bar.dart';
import '../widgets/wes_bottom_nav.dart';
import '../widgets/wes_fab.dart';
import 'player_detail_screen.dart';
import 'player_edit_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedGrade = '全員';
  String selectedPosition = '全員';
  String sortType = '背番号';

  List<Player> players = [];

  StreamSubscription? playersSubscription;

  int currentIndex = 0;

  bool get isPlayerTab => currentIndex == 0;

  @override
  void initState() {
    super.initState();
    listenPlayers();
  }

  @override
  void dispose() {
    playersSubscription?.cancel();
    super.dispose();
  }

  void listenPlayers() {
    playersSubscription = FirebaseFirestore.instance
        .collection(FirestoreCollections.players)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            setState(() {
              players = snapshot.docs
                  .map((doc) => Player.fromJson(doc.data(), id: doc.id))
                  .toList();
            });
          },
          onError: (error) {
            debugPrint('HomeScreen players stream error: $error');
          },
        );
  }

  List<Player> getFilteredPlayers() {
    List<Player> result = [...players];

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
    return Scaffold(
      appBar: const WesAppBar(unreadCount: 0),
      body: isPlayerTab ? _buildPlayerTab() : const ScheduleScreen(),
      floatingActionButton: isPlayerTab
          ? WesFab(onPressed: addPlayer, tooltip: '選手を追加')
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: WesBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }

  Widget _buildPlayerTab() {
    return CorkBoardBackground(
      child: Column(
        children: [
          PlayerFilterBar(
            grade: selectedGrade,
            position: selectedPosition,
            sortType: sortType,
            onGradeChanged: (value) => setState(() => selectedGrade = value),
            onPositionChanged: (value) =>
                setState(() => selectedPosition = value),
            onSortChanged: (value) => setState(() => sortType = value),
          ),
          Expanded(
            child: PlayerList(
              players: getFilteredPlayers(),
              onTap: openPlayerDetail,
            ),
          ),
        ],
      ),
    );
  }
}