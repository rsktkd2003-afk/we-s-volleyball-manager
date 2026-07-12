import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bulletin_providers.dart';
import '../theme/app_colors.dart';
import 'bulletin_note_tile.dart';

/// 今月の目標(既存のgoalsForMonthProviderの先頭項目)を表示する付箋。
class ScheduleGoalNote extends ConsumerWidget {
  const ScheduleGoalNote({super.key, required this.visibleMonth});

  final DateTime visibleMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsForMonthProvider(visibleMonth));

    final goal = goalsAsync.maybeWhen(
      data: (items) => items.isNotEmpty ? items.first : null,
      orElse: () => null,
    );

    return BulletinNoteTile(
      heading: '今月の目標',
      title: goal?.title,
      body: goal?.body,
      emptyText: '＋ 目標未設定',
      color: const Color(0xFFFFF3B0),
      rotation: 0.02,
      pinColor: AppColors.accent,
      width: double.infinity,
    );
  }
}
