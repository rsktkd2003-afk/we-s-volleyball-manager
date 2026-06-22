import 'package:flutter/material.dart';

import '../utils/date_time_utils.dart';
import '../utils/practice_options.dart';
import 'practice_form_fields.dart';

class AddPracticeResult {
  final DateTime startDate;
  final String startTime;
  final int durationMinutes;
  final String type;
  final String repeatType;
  final int count;

  AddPracticeResult({
    required this.startDate,
    required this.startTime,
    required this.durationMinutes,
    required this.type,
    required this.repeatType,
    required this.count,
  });
}

Future<AddPracticeResult?> showAddPracticeDialog(BuildContext context) async {
  DateTime selectedDate = DateTime.now();

  String selectedType = practiceTypes.first;
  String selectedRepeatType = repeatTypes.first;

  String selectedStartHour = '17';
  String selectedStartMinute = '00';

  String selectedDurationHour = '04';
  String selectedDurationMinute = '00';

  String selectedCount = '1';

  final hourOptions = generateHourOptions();
  final minuteOptions = generateMinuteOptions();
  final countOptions = generateCountOptions();

  return showDialog<AddPracticeResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('練習を追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('日付：${formatDate(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),

                  textDropdown(
                    value: selectedType,
                    label: '練習種別',
                    items: practiceTypes,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  textDropdown(
                    value: selectedRepeatType,
                    label: '繰り返し',
                    items: repeatTypes,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRepeatType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  sectionTitle('開始時刻'),
                  timeDropdownRow(
                    hour: selectedStartHour,
                    minute: selectedStartMinute,
                    hourOptions: hourOptions,
                    minuteOptions: minuteOptions,
                    onHourChanged: (value) {
                      setDialogState(() {
                        selectedStartHour = value;
                      });
                    },
                    onMinuteChanged: (value) {
                      setDialogState(() {
                        selectedStartMinute = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  sectionTitle('所要時間'),
                  timeDropdownRow(
                    hour: selectedDurationHour,
                    minute: selectedDurationMinute,
                    hourOptions: hourOptions,
                    minuteOptions: minuteOptions,
                    onHourChanged: (value) {
                      setDialogState(() {
                        selectedDurationHour = value;
                      });
                    },
                    onMinuteChanged: (value) {
                      setDialogState(() {
                        selectedDurationMinute = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  textDropdown(
                    value: selectedCount,
                    label: '作成回数',
                    items: countOptions,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCount = value;
                      });
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
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    AddPracticeResult(
                      startDate: selectedDate,
                      startTime: '$selectedStartHour:$selectedStartMinute',
                      durationMinutes:
                          int.parse(selectedDurationHour) * 60 +
                          int.parse(selectedDurationMinute),
                      type: selectedType,
                      repeatType: selectedRepeatType,
                      count: int.parse(selectedCount),
                    ),
                  );
                },
                child: const Text('追加'),
              ),
            ],
          );
        },
      );
    },
  );
}