import 'package:flutter/material.dart';

import '../models/team_schedule.dart';
import '../theme/app_colors.dart';
import '../utils/date_time_utils.dart';
import '../utils/schedule_visual_style.dart';

/// カレンダーで選択した1日分の予定を、読みやすい一覧で表示する。
class ScheduleDayAgenda extends StatelessWidget {
  const ScheduleDayAgenda({
    super.key,
    required this.date,
    required this.schedules,
    required this.onScheduleTap,
  });

  final DateTime date;
  final List<TeamSchedule> schedules;
  final ValueChanged<TeamSchedule> onScheduleTap;

  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.event_note,
              size: 20,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${date.month}月${date.day}日（${_weekdays[date.weekday - 1]}）の予定',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${schedules.length}件',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (schedules.isEmpty)
          const _EmptyAgenda()
        else
          for (var index = 0; index < schedules.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _ScheduleAgendaCard(
              schedule: schedules[index],
              onTap: () => onScheduleTap(schedules[index]),
            ),
          ],
      ],
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3DFD5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available, color: Colors.black38),
          SizedBox(height: 6),
          Text(
            'この日の予定はありません',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ScheduleAgendaCard extends StatelessWidget {
  const _ScheduleAgendaCard({required this.schedule, required this.onTap});

  final TeamSchedule schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = scheduleColorForTitle(schedule.title);
    final location = schedule.location.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE3DFD5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 52,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTime(schedule.start),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '〜 ${formatTime(schedule.end)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title.trim().isEmpty ? '予定' : schedule.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location.isEmpty ? '場所未設定' : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
