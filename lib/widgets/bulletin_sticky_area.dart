import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement.dart';
import '../models/team_goal.dart';
import '../providers/bulletin_providers.dart';
import '../theme/app_colors.dart';
import 'bulletin_edit_sheet.dart';
import 'bulletin_note_tile.dart';

part 'bulletin_sticky_area_widgets.dart';

class BulletinStickyArea extends ConsumerWidget {
  const BulletinStickyArea({
    super.key,
    required this.visibleMonth,
    this.isAdmin = false,
  });

  final DateTime visibleMonth;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final goalsAsync = ref.watch(goalsForMonthProvider(visibleMonth));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'チームからのお知らせ',
            onAdd: () => _showAnnouncementEditor(
              context: context,
              ref: ref,
              item: null,
            ),
          ),
          const SizedBox(height: 8),
          announcementsAsync.when(
            data: (items) => _AnnouncementWrap(
              items: items,
              onTap: (item) => _handleAnnouncementTap(
                context: context,
                ref: ref,
                item: item,
              ),
              onAdd: () => _showAnnouncementEditor(
                context: context,
                ref: ref,
                item: null,
              ),
            ),
            loading: () => const _LoadingMemo(),
            error: (error, _) => _ErrorMemo(message: error.toString()),
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: '今月の目標',
            onAdd: () => _showGoalEditor(
              context: context,
              ref: ref,
              item: null,
            ),
          ),
          const SizedBox(height: 8),
          goalsAsync.when(
            data: (items) => _GoalWrap(
              items: items,
              onTap: (item) => _handleGoalTap(
                context: context,
                ref: ref,
                item: item,
              ),
              onAdd: () => _showGoalEditor(
                context: context,
                ref: ref,
                item: null,
              ),
            ),
            loading: () => const _LoadingMemo(),
            error: (error, _) => _ErrorMemo(message: error.toString()),
          ),
        ],
      ),
    );
  }

  void _handleAnnouncementTap({
    required BuildContext context,
    required WidgetRef ref,
    required Announcement item,
  }) {
    if (_canEdit(item.createdBy)) {
      _showAnnouncementEditor(
        context: context,
        ref: ref,
        item: item,
      );
      return;
    }

    _showReadOnlyDetail(
      context: context,
      heading: 'チームからのお知らせ',
      title: item.title,
      body: item.body,
    );
  }

  void _handleGoalTap({
    required BuildContext context,
    required WidgetRef ref,
    required TeamGoal item,
  }) {
    if (_canEdit(item.createdBy)) {
      _showGoalEditor(
        context: context,
        ref: ref,
        item: item,
      );
      return;
    }

    _showReadOnlyDetail(
      context: context,
      heading: '今月の目標',
      title: item.title,
      body: item.body,
    );
  }

  bool _canEdit(String createdBy) {
    if (isAdmin) return true;
    if (createdBy.trim().isEmpty) return false;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == createdBy;
  }

  Future<void> _showAnnouncementEditor({
    required BuildContext context,
    required WidgetRef ref,
    required Announcement? item,
  }) {
    final repository = ref.read(bulletinRepositoryProvider);

    return showBulletinEditSheet(
      context: context,
      heading: item == null ? 'お知らせを追加' : 'お知らせを編集',
      initialTitle: item?.title,
      initialBody: item?.body,
      onSubmit: (title, body) async {
        if (item == null) {
          await repository.addAnnouncement(
            title: title,
            body: body,
          );
        } else {
          await repository.updateAnnouncement(
            id: item.id,
            title: title,
            body: body,
            sortOrder: item.sortOrder,
            isPinned: item.isPinned,
          );
        }
      },
      onDelete: item == null
          ? null
          : () async {
              await repository.deleteAnnouncement(item.id);
            },
    );
  }

  Future<void> _showGoalEditor({
    required BuildContext context,
    required WidgetRef ref,
    required TeamGoal? item,
  }) {
    final repository = ref.read(bulletinRepositoryProvider);

    return showBulletinEditSheet(
      context: context,
      heading: item == null ? '今月の目標を追加' : '今月の目標を編集',
      initialTitle: item?.title,
      initialBody: item?.body,
      onSubmit: (title, body) async {
        if (item == null) {
          await repository.addGoal(
            month: visibleMonth,
            title: title,
            body: body,
          );
        } else {
          await repository.updateGoal(
            id: item.id,
            title: title,
            body: body,
            sortOrder: item.sortOrder,
          );
        }
      },
      onDelete: item == null
          ? null
          : () async {
              await repository.deleteGoal(item.id);
            },
    );
  }

  void _showReadOnlyDetail({
    required BuildContext context,
    required String heading,
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(heading),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (body.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(body),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}