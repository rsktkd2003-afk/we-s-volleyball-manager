import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../models/team_schedule.dart';

class TeamScheduleDataSource extends CalendarDataSource {
  TeamScheduleDataSource(List<TeamSchedule> schedules) {
    appointments = schedules;
  }

  TeamSchedule _schedule(int index) {
    return appointments![index] as TeamSchedule;
  }

  @override
  DateTime getStartTime(int index) {
    return _schedule(index).start;
  }

  @override
  DateTime getEndTime(int index) {
    final schedule = _schedule(index);

    if (schedule.end.isAfter(schedule.start)) {
      return schedule.end;
    }

    return schedule.start.add(const Duration(minutes: 30));
  }

  @override
  String getSubject(int index) {
    final title = _schedule(index).title.trim();
    return title.isEmpty ? '予定' : title;
  }

  @override
  Color getColor(int index) {
    return _schedule(index).color;
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}