import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 画面上部の紙タブ（PLAYER SCOUTING / TEAM SCHEDULE 切替）。
class WesTopTabs extends StatelessWidget {
  const WesTopTabs({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = ['PLAYER SCOUTING', 'TEAM SCHEDULE'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7E4DE),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            _TabItem(
              label: _tabs[i],
              selected: currentIndex == i,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.paper : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, -2),
                    color: Color(0x14000000),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.push_pin,
                size: 15,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
