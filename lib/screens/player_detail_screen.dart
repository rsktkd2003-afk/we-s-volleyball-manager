import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/position_fit_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ability_radar_chart.dart';
import '../widgets/pin_badge.dart';
import '../widgets/player_issue_section.dart';

part 'player_detail_screen_layout.dart';
part 'player_detail_screen_cards.dart';
part 'player_detail_screen_chrome.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({
    super.key,
    required this.player,
  });

  final Player player;

  static const Color _accentRed = Color(0xFFC0392B);
  static const Color _boardColor = Color(0xFFE9E8E3);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _boardColor,
        appBar: AppBar(
          title: Text(player.name),
          backgroundColor: const Color(0xFFF7F5EF),
          foregroundColor: const Color(0xFF252525),
          elevation: 1,
          actions: [
            IconButton(
              tooltip: '編集',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
            IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              color: _accentRed,
              onPressed: () => Navigator.pop(context, 'delete'),
            ),
          ],
          bottom: const TabBar(
            labelColor: _accentRed,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: _accentRed,
            tabs: [
              Tab(
                icon: Icon(Icons.badge_outlined),
                text: 'スカウトカード',
              ),
              Tab(
                icon: Icon(Icons.flag_outlined),
                text: '改善点',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ScoutingBoard(player: player),
            PlayerIssueSection(player: player),
          ],
        ),
      ),
    );
  }
}

class _ScoutingBoard extends StatelessWidget {
  const _ScoutingBoard({
    required this.player,
  });

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
              colors: [
                Color(0xFFF1F0EC),
                Color(0xFFE1E0DC),
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 10,
                left: 10,
                child: _BoardScrew(),
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: _BoardScrew(),
              ),
              const Positioned(
                bottom: 10,
                left: 10,
                child: _BoardScrew(),
              ),
              const Positioned(
                bottom: 10,
                right: 10,
                child: _BoardScrew(),
              ),
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
                        : _CompactLayout(
                            player: player,
                            isTablet: isTablet,
                          ),
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
