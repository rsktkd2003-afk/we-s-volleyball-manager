import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/practice.dart';

class PracticeCalendarScreen extends StatefulWidget {
  final List<Practice> practices;

  const PracticeCalendarScreen({super.key, required this.practices});

  @override
  State<PracticeCalendarScreen> createState() => _PracticeCalendarScreenState();
}

class _PracticeCalendarScreenState extends State<PracticeCalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  List<Practice> getPracticesForDay(DateTime day) {
    final target =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    return widget.practices.where((practice) {
      return practice.date == target;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPractices = getPracticesForDay(selectedDay ?? focusedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('練習カレンダー')),
      body: Column(
        children: [
          TableCalendar<Practice>(
            firstDay: DateTime(2024),
            lastDay: DateTime(2035),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(selectedDay, day);
            },
            eventLoader: getPracticesForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selectedPractices.isEmpty
                ? const Center(child: Text('この日の練習はありません'))
                : ListView.builder(
                    itemCount: selectedPractices.length,
                    itemBuilder: (context, index) {
                      final practice = selectedPractices[index];

                      return ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(
                          '${practice.type} / ${practice.startTime}〜',
                        ),
                        subtitle: Text('所要時間: ${practice.durationMinutes}分'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
