import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/utils/date_time_utils.dart';

void main() {
  group('date and time utilities', () {
    test('generates hour options from 00 through 24', () {
      final options = generateHourOptions();

      expect(options, hasLength(25));
      expect(options.first, '00');
      expect(options.last, '24');
    });

    test('generates minute options in five-minute intervals', () {
      expect(
        generateMinuteOptions(),
        ['00', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'],
      );
    });

    test('formats and parses dates', () {
      final date = DateTime(2026, 7, 18);

      expect(formatDate(date), '2026/07/18');
      expect(parseDate('2026/07/18'), date);
      expect(parseDate('invalid'), isNull);
    });

    test('formats times', () {
      final dateTime = DateTime(2026, 7, 18, 9, 5);

      expect(formatTime(dateTime), '09:05');
      expect(formatMonthDayTime(dateTime), '7/18 09:05');
    });
  });
}
