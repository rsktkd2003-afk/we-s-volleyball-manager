import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bulletin_providers.dart';
import '../theme/app_colors.dart';
import '../providers/player_link_request_providers.dart';
import 'bulletin_sticky_area.dart';

/// お知らせ(既存のannouncementsProvider)を箇条書きでまとめて表示するMEMO付箋。
class ScheduleMemoNote extends ConsumerWidget {
  const ScheduleMemoNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    final lines = announcementsAsync.maybeWhen(
      // 初期画面は参考デザインに合わせて2件に絞り、タップで全件を開く。
      data: (items) => items.take(2).map((a) => a.title).toList(),
      orElse: () => const <String>[],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openDetails(context, ref),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E2D9)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 6),
              color: Color(0x1617314F),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 19,
                  color: AppColors.action,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'チームメモ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    announcementsAsync.maybeWhen(
                      data: (items) => '${items.length}件',
                      orElse: () => '…',
                    ),
                    style: const TextStyle(
                      color: AppColors.action,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (lines.isEmpty)
              Text(
                announcementsAsync.when(
                  data: (_) => 'お知らせはまだありません',
                  loading: () => 'メモを読み込んでいます…',
                  error: (_, _) => 'メモを取得できませんでした。タップして確認',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.editorialAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
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
                visibleMonth: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                ),
                isAdmin: ref
                    .watch(currentUserIsAdminProvider)
                    .when(
                      skipLoadingOnRefresh: false,
                      skipLoadingOnReload: false,
                      data: (value) => value,
                      loading: () => false,
                      error: (_, _) => false,
                    ),
                showAnnouncements: true,
                showGoals: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
