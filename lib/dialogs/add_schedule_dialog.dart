import 'package:flutter/material.dart';

import '../models/schedule_template.dart';
import '../theme/app_colors.dart';
import 'template_delete_dialog.dart' as template_delete;

/// 予定追加ダイアログの入力結果。
class AddScheduleInput {
  const AddScheduleInput({
    required this.title,
    required this.location,
    required this.start,
    required this.durationMinutes,
    required this.repeatType,
    required this.count,
    required this.saveAsTemplate,
  });

  final String title;
  final String location;
  final DateTime start;
  final int durationMinutes;
  final String repeatType;
  final int count;
  final bool saveAsTemplate;
}

const _durationItems = [
  DropdownMenuItem(value: 60, child: Text('所要時間 1時間')),
  DropdownMenuItem(value: 90, child: Text('所要時間 1時間30分')),
  DropdownMenuItem(value: 120, child: Text('所要時間 2時間')),
  DropdownMenuItem(value: 150, child: Text('所要時間 2時間30分')),
  DropdownMenuItem(value: 180, child: Text('所要時間 3時間')),
  DropdownMenuItem(value: 240, child: Text('所要時間 4時間')),
];

const _repeatItems = [
  DropdownMenuItem(value: '単発', child: Text('単発')),
  DropdownMenuItem(value: '毎日', child: Text('毎日')),
  DropdownMenuItem(value: '毎週', child: Text('毎週')),
  DropdownMenuItem(value: '毎月', child: Text('毎月')),
];

/// 予定追加ダイアログを表示し、確定時は入力値を、キャンセル時は null を返す。
Future<AddScheduleInput?> showAddScheduleDialog({
  required BuildContext context,
  required List<ScheduleTemplate> templates,
  required Future<void> Function(ScheduleTemplate) onDeleteTemplate,
}) async {
  final titleController = TextEditingController();
  final locationController = TextEditingController();

  // ダイアログ内で削除を反映できるようローカルコピーを持つ
  final localTemplates = [...templates];

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
  int durationMinutes = 180;
  bool saveAsTemplate = false;
  String repeatType = '単発';
  int count = 1;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('予定追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (localTemplates.isNotEmpty)
                    DropdownButton<ScheduleTemplate>(
                      isExpanded: true,
                      hint: const Text('テンプレートを選択'),
                      items: localTemplates
                          .map(
                            (template) => DropdownMenuItem(
                              value: template,
                              child: Text(template.title),
                            ),
                          )
                          .toList(),
                      onChanged: (template) {
                        if (template == null) return;

                        setDialogState(() {
                          titleController.text = template.title;
                          locationController.text = template.location;
                          durationMinutes = template.durationMinutes;
                        });
                      },
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: localTemplates.isEmpty
                          ? null
                          : () async {
                              final deleted = await template_delete
                                  .showTemplateDeleteDialog(
                                    context: context,
                                    templates: localTemplates,
                                    onDelete: (template) async {
                                      await onDeleteTemplate(template);
                                      localTemplates.remove(template);
                                    },
                                  );

                              if (deleted == true) {
                                setDialogState(() {});
                              }
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('テンプレート削除'),
                    ),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: '場所'),
                  ),
                  const SizedBox(height: 12),
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
                  DropdownButton<int>(
                    value: durationMinutes,
                    isExpanded: true,
                    items: _durationItems,
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => durationMinutes = value);
                    },
                  ),
                  DropdownButton<String>(
                    value: repeatType,
                    isExpanded: true,
                    items: _repeatItems,
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => repeatType = value);
                    },
                  ),
                  DropdownButton<int>(
                    value: count,
                    isExpanded: true,
                    items: List.generate(20, (index) {
                      final value = index + 1;
                      return DropdownMenuItem(
                        value: value,
                        child: Text('作成回数 $value回'),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => count = value);
                    },
                  ),
                  CheckboxListTile(
                    value: saveAsTemplate,
                    title: const Text('テンプレートとして保存'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setDialogState(() => saveAsTemplate = value ?? false);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('追加'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != true) return null;

  final title = titleController.text.trim().isEmpty
      ? '予定'
      : titleController.text.trim();

  return AddScheduleInput(
    title: title,
    location: locationController.text.trim(),
    start: DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    ),
    durationMinutes: durationMinutes,
    repeatType: repeatType,
    count: count,
    saveAsTemplate: saveAsTemplate,
  );
}