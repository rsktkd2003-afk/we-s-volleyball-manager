import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement.dart';
import '../models/team_goal.dart';
import '../repositories/bulletin_repository.dart';

final bulletinRepositoryProvider = Provider<BulletinRepository>((ref) {
  return BulletinRepository();
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final repository = ref.watch(bulletinRepositoryProvider);

  return repository.watchAnnouncements().map((items) {
    final sorted = [...items];

    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return sorted;
  });
});

final goalsForMonthProvider =
    StreamProvider.family<List<TeamGoal>, DateTime>((ref, month) {
  final repository = ref.watch(bulletinRepositoryProvider);

  return repository.watchGoalsForMonth(month).map((items) {
    final sorted = [...items];

    sorted.sort((a, b) {
      final sortOrderResult = a.sortOrder.compareTo(b.sortOrder);
      if (sortOrderResult != 0) {
        return sortOrderResult;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return sorted;
  });
});