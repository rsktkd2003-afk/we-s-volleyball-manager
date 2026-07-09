import 'package:flutter/material.dart';

import 'pin_badge.dart';

class WesBottomNav extends StatelessWidget {
  const WesBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color _paper = Color(0xFFFFFDF7);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: _paper,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      height: 74,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 10,
            top: -4,
            child: PinBadge(size: 11, seed: 1),
          ),
          const Positioned(
            right: 10,
            top: -4,
            child: PinBadge(size: 11, seed: 3),
          ),
          Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.people,
                  label: '選手',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: _NavItem(
                  icon: Icons.calendar_month,
                  label: '予定',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _red = Color(0xFFD32F2F);
  static const Color _textSub = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _red : _textSub;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      // 修正: 固定の top padding 8 + アイコン + テキストの合計高さが
      // BottomAppBar 内の利用可能高さ(約42px)を超えて
      // 「RenderFlex overflowed by 6.0 pixels」が発生していた。
      // Center + FittedBox(scaleDown) で、収まるときは等倍のまま中央配置、
      // 収まらない環境でも縮小してオーバーフローを防ぐ。
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}