import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/team_schedule.dart';
import 'package:volleyball_app/utils/schedule_utils.dart';

void main() {
  group('schedulesForDate', () {
    test('returns schedules for the selected date in start-time order', () {
      final schedules = [
        _schedule(
          title: '夜練習',
          start: DateTime(2026, 7, 21, 19),
          end: DateTime(2026, 7, 21, 21),
        ),
        _schedule(
          title: '朝練習',
          start: DateTime(2026, 7, 21, 9),
          end: DateTime(2026, 7, 21, 11),
        ),
        _schedule(
          title: '別日の練習',
          start: DateTime(2026, 7, 22, 9),
          end: DateTime(2026, 7, 22, 11),
        ),
      ];

      final result = schedulesForDate(schedules, DateTime(2026, 7, 21));

      expect(result.map((schedule) => schedule.title), ['朝練習', '夜練習']);
    });

    test('includes a schedule that crosses midnight', () {
      final schedule = _schedule(
        title: '遠征',
        start: DateTime(2026, 7, 21, 23),
        end: DateTime(2026, 7, 22, 1),
      );

      expect(schedulesForDate([schedule], DateTime(2026, 7, 21)), [schedule]);
      expect(schedulesForDate([schedule], DateTime(2026, 7, 22)), [schedule]);
      expect(schedulesForDate([schedule], DateTime(2026, 7, 23)), isEmpty);
    });

    test('uses a 30-minute fallback when the end is invalid', () {
      final schedule = _schedule(
        title: '終了時刻未設定',
        start: DateTime(2026, 7, 21, 23, 50),
        end: DateTime(2026, 7, 21, 23, 50),
      );

      expect(schedulesForDate([schedule], DateTime(2026, 7, 22)), [schedule]);
    });
  });
}

TeamSchedule _schedule({
  required String title,
  required DateTime start,
  required DateTime end,
}) {
  return TeamSchedule(
    title: title,
    location: '',
    start: start,
    end: end,
    durationMinutes: end.difference(start).inMinutes,
    color: Colors.blue,
  );
}
