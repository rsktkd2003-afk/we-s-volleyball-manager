import 'package:flutter/material.dart';

import '../models/schedule_template.dart';
import '../utils/schedule_utils.dart';

Future<bool?> showTemplateDeleteDialog({
  required BuildContext context,
  required List<ScheduleTemplate> templates,
  required Future<void> Function(ScheduleTemplate template) onDelete,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('テンプレート削除'),
        content: SizedBox(
          width: double.maxFinite,
          child: templates.isEmpty
              ? const Text('削除できるテンプレートがありません')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];

                    return ListTile(
                      title: Text(template.title),
                      subtitle: Text(
                        '${template.location} / ${formatDuration(template.durationMinutes)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await onDelete(template);

                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('閉じる'),
          ),
        ],
      );
    },
  );
}