import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_template.dart';
import '../models/team_schedule.dart';
import '../repositories/schedule_repository.dart';
import 'cancelable_stream_provider.dart';

final scheduleReadRepositoryProvider = Provider<ScheduleReadRepository>((ref) {
  return const FirebaseScheduleReadRepository();
});

/// schedules を開始日時順に取得する。購読者がいなくなると即座に購読を解除する。
final schedulesProvider = cancelableStreamProvider<List<TeamSchedule>>((ref) {
  final repository = ref.watch(scheduleReadRepositoryProvider);
  return repository.watchSchedules();
});

/// schedule_templates 全件。購読者がいなくなると即座に購読を解除する。
final scheduleTemplatesProvider =
    cancelableStreamProvider<List<ScheduleTemplate>>((ref) {
  final repository = ref.watch(scheduleReadRepositoryProvider);
  return repository.watchTemplates();
});
