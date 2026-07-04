import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/team_schedule.dart';
import '../repositories/schedule_repository.dart';

Future<void> showEditScheduleDialog(
  BuildContext context,
  TeamSchedule schedule,
) async {
  final titleController = TextEditingController(text: schedule.title);
  final locationController = TextEditingController(text: schedule.location);

  DateTime selectedDate = schedule.start;
  TimeOfDay startTime = TimeOfDay.fromDateTime(schedule.start);
  final int durationMinutes = schedule.durationMinutes;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('予定編集'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: '場所'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(
                      '日付 ${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2035),
                      );

                      if (picked == null) return;
                      setDialogState(() => selectedDate = picked);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text('開始 ${startTime.format(context)}'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );

                      if (picked == null) return;
                      setDialogState(() => startTime = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != true || schedule.id == null) return;

  final start = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    startTime.hour,
    startTime.minute,
  );

  await ScheduleRepository.updateSchedule(schedule.id!, {
    'title': titleController.text,
    'location': locationController.text,
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(start.add(Duration(minutes: durationMinutes))),
    'durationMinutes': durationMinutes,
  });
}