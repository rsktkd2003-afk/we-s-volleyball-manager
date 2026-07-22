import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../datasources/team_schedule_data_source.dart';
import '../models/team_schedule.dart';
import '../theme/app_colors.dart';
import '../utils/schedule_visual_style.dart';

/// 月全体の予定量を把握し、日付を選択するためのカレンダー。
class ScheduleCalendar extends StatelessWidget {
  const ScheduleCalendar({
    super.key,
    required this.controller,
    required this.dataSource,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onViewChanged,
  });

  final CalendarController controller;
  final TeamScheduleDataSource dataSource;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<ViewChangedDetails> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      controller: controller,
      view: CalendarView.month,
      firstDayOfWeek: 1,
      headerDateFormat: 'yyyy年M月',
      todayHighlightColor: AppColors.accent,
      backgroundColor: Colors.white,
      cellBorderColor: const Color(0xFFE3DFD5),
      headerStyle: const CalendarHeaderStyle(
        backgroundColor: AppColors.paper,
        textStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      viewHeaderStyle: const ViewHeaderStyle(
        backgroundColor: AppColors.paper,
        dayTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      dataSource: dataSource,
      onViewChanged: onViewChanged,
      monthCellBuilder: _buildMonthCell,
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.none,
        showAgenda: false,
      ),
      onTap: (details) {
        final date = details.date;
        if (date != null) onDateSelected(date);
      },
    );
  }

  Widget _buildMonthCell(BuildContext context, MonthCellDetails details) {
    final date = details.date;
    final middleDate = details.visibleDates[details.visibleDates.length ~/ 2];
    final isVisibleMonth =
        date.year == middleDate.year && date.month == middleDate.month;
    final isSelected = _isSameDay(date, selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final schedules = details.appointments.whereType<TeamSchedule>().toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFF2F2)
            : isVisibleMonth
            ? Colors.white
            : const Color(0xFFF7F6F2),
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : const Color(0xFFE3DFD5),
          width: isSelected ? 2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 23,
              height: 23,
              alignment: Alignment.center,
              decoration: isToday
                  ? const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isToday
                      ? Colors.white
                      : isVisibleMonth
                      ? AppColors.textPrimary
                      : Colors.black38,
                  fontSize: 11,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (schedules.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (final schedule in schedules.take(2)) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: scheduleColorForTitle(schedule.title),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                      if (schedules.length > 2)
                        const Text(
                          '+',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${schedules.length}件',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
