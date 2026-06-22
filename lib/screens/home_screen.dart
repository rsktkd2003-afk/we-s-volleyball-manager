import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../dialogs/add_player_dialog.dart';
import '../models/player.dart';
import '../widgets/player_list.dart';
import 'player_detail_screen.dart';
import 'schedule_screen.dart';
import 'player_edit_screen.dart';
import '../services/team_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? teamId;

  StreamSubscription? playersSubscription;

  int currentIndex = 0;

  bool get isPlayerTab => currentIndex == 0;

  @override
  void initState() {
    super.initState();
    initTeam();
  }

Future<void> initTeam() async {
  teamId = await TeamService.getCurrentTeamId();
  listenPlayers();
}


  void listenPlayers() {
    playersSubscription = FirebaseFirestore.instance
        .collection('players')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        players = snapshot.docs.map((doc) {
          return Player.fromJson(doc.data(), id: doc.id);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    playersSubscription?.cancel();
    super.dispose();
  }

  List<Player> getFilteredPlayers() {
  List<Player> result = [...players];

  if (selectedGrade != '全員') {
    result = result.where((p) => p.grade == selectedGrade).toList();
  }

  if (selectedPosition != '全員') {
    result = result.where((p) => p.position == selectedPosition).toList();
  }

  if (sortType == '背番号') {
    result.sort((a, b) => a.number.compareTo(b.number));
  } else if (sortType == '学年') {
    result.sort((a, b) => a.grade.compareTo(b.grade));
  } else if (sortType == '名前') {
    result.sort((a, b) => a.name.compareTo(b.name));
  }

  return result;
}

  Future<void> addPlayer() async {
    final name = await showAddPlayerDialog(context);

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
        .collection('players')
        .add({
          ...newPlayer.toJson(),
          'teamId': teamId,
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

    if (result == 'delete') {
      await FirebaseFirestore.instance
          .collection('players')
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
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isPlayerTab ? '選手' : '予定'),
      ),
      body: isPlayerTab
    ? Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedGrade,
                        decoration: const InputDecoration(
                          labelText: '学年',
                          border: OutlineInputBorder(),
                        ),
                        items: ['全員', '1年', '2年', '3年', '4年', '社会人', '未設定']
                            .map((grade) => DropdownMenuItem(
                                  value: grade,
                                  child: Text(grade),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGrade = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'ポジション',
                          border: OutlineInputBorder(),
                        ),
                        items: ['全員', 'S', 'WS', 'MB', 'OP', 'L', '未設定']
                            .map((position) => DropdownMenuItem(
                                  value: position,
                                  child: Text(position),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPosition = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: sortType,
                  decoration: const InputDecoration(
                    labelText: '並び順',
                    border: OutlineInputBorder(),
                  ),
                  items: ['背番号', '学年', '名前']
                      .map((sort) => DropdownMenuItem(
                            value: sort,
                            child: Text(sort),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      sortType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: PlayerList(
              players: getFilteredPlayers(),
              onTap: openPlayerDetail,
            ),
          ),
        ],
      )
    : const ScheduleScreen(),
    
      floatingActionButton: isPlayerTab
          ? FloatingActionButton(
              onPressed: addPlayer,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '選手',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '予定',
          ),
        ],
      ),
    );
  }
}