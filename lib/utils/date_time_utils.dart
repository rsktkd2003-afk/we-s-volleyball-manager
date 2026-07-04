List<String> generateHourOptions() {
  final hours = <String>[];

  for (int hour = 0; hour <= 24; hour++) {
    hours.add(hour.toString().padLeft(2, '0'));
  }

  return hours;
}

List<String> generateMinuteOptions() {
  return [
    '00',
    '05',
    '10',
    '15',
    '20',
    '25',
    '30',
    '35',
    '40',
    '45',
    '50',
    '55',
  ];
}

String formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}/$month/$day';
}

DateTime? parseDate(String text) {
  try {
    final parts = text.split('/');

    if (parts.length != 3) {
      return null;
    }

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

String formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String formatMonthDayTime(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day} ${formatTime(dateTime)}';
}
