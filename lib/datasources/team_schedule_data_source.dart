import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../models/team_schedule.dart';

class TeamScheduleDataSource extends CalendarDataSource {
  TeamScheduleDataSource(List<TeamSchedule> schedules) {
    appointments = schedules;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].start;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].end;
  }

  @override
  String getSubject(int index) {
    return appointments![index].title;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }
}
