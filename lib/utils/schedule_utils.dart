import '../models/team_schedule.dart';

DateTime getRepeatedStart(DateTime base, String repeatType, int index) {
  switch (repeatType) {
    case '毎日':
      return base.add(Duration(days: index));

    case '毎週':
      return base.add(Duration(days: index * 7));

    case '毎月':
      return DateTime(
        base.year,
        base.month + index,
        base.day,
        base.hour,
        base.minute,
      );

    default:
      return base;
  }
}

/// 指定日に少しでも重なる予定を、開始時刻順で返す。
List<TeamSchedule> schedulesForDate(
  Iterable<TeamSchedule> schedules,
  DateTime date,
) {
  final dayStart = DateTime(date.year, date.month, date.day);
  final nextDay = dayStart.add(const Duration(days: 1));

  final result = schedules.where((schedule) {
    final effectiveEnd = schedule.end.isAfter(schedule.start)
        ? schedule.end
        : schedule.start.add(const Duration(minutes: 30));

    return schedule.start.isBefore(nextDay) && effectiveEnd.isAfter(dayStart);
  }).toList();

  result.sort((first, second) => first.start.compareTo(second.start));
  return result;
}

String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;

  if (restMinutes == 0) {
    return '$hours時間';
  }

  return '$hours時間$restMinutes分';
}
