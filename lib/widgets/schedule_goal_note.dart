import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bulletin_providers.dart';
import '../theme/app_colors.dart';
import '../providers/player_link_request_providers.dart';
import 'bulletin_sticky_area.dart';

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetails(context, ref),
        child: Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7E2D9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1617314F),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final titleSize = constraints.maxWidth < 240 ? 18.0 : 22.0;
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${visibleMonth.month}月の目標',
                          style: TextStyle(
                            color: AppColors.editorialAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          goal?.title ??
                              goalsAsync.when(
                                data: (_) => '目標はまだ設定されていません',
                                loading: () => '目標を読み込んでいます…',
                                error: (_, _) => '目標を取得できませんでした。タップして確認',
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.action,
                            fontSize: titleSize,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (goal?.body.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 6),
                          Text(
                            goal!.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.editorialAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.sports_volleyball_outlined,
                    size: 48,
                    color: Color(0x2617314F),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Consumer(
              builder: (context, ref, _) => BulletinStickyArea(
                visibleMonth: visibleMonth,
                isAdmin: ref
                    .watch(currentUserIsAdminProvider)
                    .when(
                      skipLoadingOnRefresh: false,
                      skipLoadingOnReload: false,
                      data: (value) => value,
                      loading: () => false,
                      error: (_, _) => false,
                    ),
                showAnnouncements: false,
                showGoals: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
