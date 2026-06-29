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

String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;

  if (restMinutes == 0) {
    return '$hours時間';
  }

  return '$hours時間$restMinutes分';
}
