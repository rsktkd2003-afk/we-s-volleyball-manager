import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_link_request_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/wes_app_bar.dart';
import 'home_screen.dart';
import 'members_screen.dart';
import 'notification_center_screen.dart';
import 'practice_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';

/// AppShell のタブ。並び順がナビゲーションの表示順になる。
enum AppShellTab {
  home('ホーム', Icons.dashboard_outlined, Icons.dashboard),
  schedule('予定', Icons.calendar_month_outlined, Icons.calendar_month),
  practice(
    '練習',
    Icons.sports_volleyball_outlined,
    Icons.sports_volleyball,
  ),
  members('メンバー', Icons.groups_outlined, Icons.groups);

  const AppShellTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// 画面幅によるナビゲーションの切り替え基準。
class AppShellBreakpoints {
  AppShellBreakpoints._();

  /// これ未満は Bottom Navigation。
  static const double rail = 600;

  /// これ以上は Extended NavigationRail。
  static const double extendedRail = 1200;
}

/// ログイン後のルート画面。WE'S CLUB BOARD の4タブを切り替える。
///
/// 各タブは初めて開いたときに生成し、以後は状態を保持する(IndexedStack)。
/// まだ開いていないタブは生成しないため、そのタブの Firestore 購読も
/// 始まらない。開いたタブの購読は、タブ切り替えのたびに作り直すと
/// 初回スナップショットの全件読み取りが繰り返されるため、維持する。
/// ログアウト時は AppShell ごと破棄され、すべての購読が解除される。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialTab = AppShellTab.home});

  final AppShellTab initialTab;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late AppShellTab _currentTab = widget.initialTab;
  late final Set<AppShellTab> _openedTabs = {widget.initialTab};

  // 画面幅の変化でレイアウト(BottomNav / Rail)が切り替わっても、
  // タブの状態を失わないよう同じ要素として扱う。
  final GlobalKey _tabStackKey = GlobalKey(debugLabel: 'AppShell tabs');

  void _selectTab(AppShellTab tab) {
    if (tab == _currentTab) return;
    setState(() {
      _currentTab = tab;
      _openedTabs.add(tab);
    });
  }

  Future<void> _openProfile() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationCenterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 権限の読み込み中・エラー時は管理者として扱わない。
    final isAdmin = ref.watch(currentUserIsAdminProvider).maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );
    final pendingRequestCount = isAdmin
        ? ref.watch(pendingPlayerLinkRequestsProvider).maybeWhen(
              data: (requests) => requests.length,
              orElse: () => 0,
            )
        : 0;

    final tabs = _buildTabStack();

    // 実際に使える幅で切り替える(ウィンドウ幅の変更にも追従する)。
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useBottomNavigation = width < AppShellBreakpoints.rail;
        final extendedRail = width >= AppShellBreakpoints.extendedRail;

        return Scaffold(
          backgroundColor: AppColors.boardBackground,
          appBar: WesAppBar(
            unreadCount: pendingRequestCount,
            onTapNotifications: _openNotifications,
            onTapSettings: _openSettings,
            onTapProfile: _openProfile,
          ),
          body: useBottomNavigation
              ? tabs
              : Row(
                  children: [
                    _ClubNavigationRail(
                      currentTab: _currentTab,
                      extended: extendedRail,
                      onSelected: _selectTab,
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFD9D2C3),
                    ),
                    Expanded(child: tabs),
                  ],
                ),
          bottomNavigationBar: useBottomNavigation
              ? _ClubNavigationBar(
                  currentTab: _currentTab,
                  onSelected: _selectTab,
                )
              : null,
        );
      },
    );
  }

  Widget _buildTabStack() {
    return IndexedStack(
      key: _tabStackKey,
      index: _currentTab.index,
      children: [
        for (final tab in AppShellTab.values)
          if (_openedTabs.contains(tab))
            // 非表示タブのアニメーションを止める。
            TickerMode(
              enabled: tab == _currentTab,
              child: KeyedSubtree(
                key: ValueKey(tab),
                child: _buildTab(tab),
              ),
            )
          else
            const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTab(AppShellTab tab) {
    return switch (tab) {
      AppShellTab.home => const HomeScreen(),
      AppShellTab.schedule => const ScheduleScreen(),
      AppShellTab.practice => const PracticeScreen(),
      AppShellTab.members => const MembersScreen(),
    };
  }
}

class _ClubNavigationBar extends StatelessWidget {
  const _ClubNavigationBar({
    required this.currentTab,
    required this.onSelected,
  });

  final AppShellTab currentTab;
  final ValueChanged<AppShellTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (index) =>
          onSelected(AppShellTab.values[index]),
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accent.withValues(alpha: 0.14),
      elevation: 6,
      shadowColor: const Color(0x33000000),
      destinations: [
        for (final tab in AppShellTab.values)
          NavigationDestination(
            icon: Icon(tab.icon, color: AppColors.textSecondary),
            selectedIcon: Icon(tab.selectedIcon, color: AppColors.accent),
            label: tab.label,
          ),
      ],
    );
  }
}

class _ClubNavigationRail extends StatelessWidget {
  const _ClubNavigationRail({
    required this.currentTab,
    required this.extended,
    required this.onSelected,
  });

  final AppShellTab currentTab;
  final bool extended;
  final ValueChanged<AppShellTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      right: false,
      child: NavigationRail(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) =>
            onSelected(AppShellTab.values[index]),
        extended: extended,
        minExtendedWidth: 200,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.accent.withValues(alpha: 0.14),
        selectedIconTheme: const IconThemeData(color: AppColors.accent),
        unselectedIconTheme:
            const IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        leading: extended
            ? const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Text(
                  "WE'S CLUB BOARD",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              )
            : null,
        destinations: [
          for (final tab in AppShellTab.values)
            NavigationRailDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: Text(tab.label),
            ),
        ],
      ),
    );
  }
}
