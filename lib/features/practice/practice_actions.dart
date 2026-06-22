import 'package:flutter/material.dart';

import '../../dialogs/add_practice_dialog.dart';
import '../../dialogs/practice_add_menu_dialog.dart';
import '../../dialogs/save_template_dialog.dart';
import '../../dialogs/template_name_dialog.dart';
import '../../dialogs/template_select_dialog.dart';
import '../../models/practice.dart';
import '../../models/practice_template.dart';
import '../../utils/date_time_utils.dart';

class PracticeActions {
  PracticeActions({
    required this.context,
    required this.practices,
    required this.practiceTemplates,
    required this.onChanged,
    required this.onSave,
  });

  final BuildContext context;
  final List<Practice> practices;
  final List<PracticeTemplate> practiceTemplates;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

  Future<void> showPracticeAddMenu() async {
    final result = await showPracticeAddMenuDialog(context);

    if (result == 'template') {
      await addPracticeFromTemplate();
    } else if (result == 'custom') {
      await addPractice();
    }
  }

  Future<void> addPractice() async {
    final result = await showAddPracticeDialog(context);

    if (result == null) return;

    await addPractices(
      startDate: result.startDate,
      startTime: result.startTime,
      durationMinutes: result.durationMinutes,
      type: result.type,
      repeatType: result.repeatType,
      count: result.count,
    );

    final shouldSave = await showSaveTemplateDialog(context);
    if (shouldSave != true) return;

    final templateName = await showTemplateNameDialog(context);
    if (templateName == null || templateName.trim().isEmpty) return;

    practiceTemplates.add(
      PracticeTemplate(
        name: templateName.trim(),
        type: result.type,
        startTime: result.startTime,
        durationMinutes: result.durationMinutes,
        repeatType: result.repeatType,
        count: result.count,
      ),
    );

    onChanged();
    await onSave();
  }

  Future<void> addPracticeFromTemplate() async {
    if (practiceTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存済みのテンプレートがありません。')),
      );
      return;
    }

    final template = await showTemplateSelectDialog(
      context,
      practiceTemplates,
      onChanged: onChanged,
      onSave: onSave,
    );

    if (template == null) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (selectedDate == null) return;

    await addPractices(
      startDate: selectedDate,
      startTime: template.startTime,
      durationMinutes: template.durationMinutes,
      type: template.type,
      repeatType: template.repeatType,
      count: template.count,
    );
  }

  Future<void> addPractices({
    required DateTime startDate,
    required String startTime,
    required int durationMinutes,
    required String type,
    required String repeatType,
    required int count,
  }) async {
    if (count <= 0) return;

    for (int i = 0; i < count; i++) {
      final date = getRepeatedDate(startDate, repeatType, i);

      practices.add(
        Practice(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          date: formatDate(date),
          startTime: startTime,
          durationMinutes: durationMinutes,
          type: type,
          attendance: {},
        ),
      );
    }

    onChanged();
    await onSave();
  }

  DateTime getRepeatedDate(DateTime startDate, String repeatType, int index) {
    if (repeatType == '毎日') {
      return startDate.add(Duration(days: index));
    }

    if (repeatType == '毎週') {
      return startDate.add(Duration(days: index * 7));
    }

    if (repeatType == '毎月') {
      return DateTime(startDate.year, startDate.month + index, startDate.day);
    }

    return startDate;
  }
}