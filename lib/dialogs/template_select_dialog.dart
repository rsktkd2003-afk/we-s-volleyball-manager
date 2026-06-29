import 'package:flutter/material.dart';

import '../models/practice_template.dart';

Future<PracticeTemplate?> showTemplateSelectDialog(
  BuildContext context,
  List<PracticeTemplate> templates, {
  required VoidCallback onChanged,
  required Future<void> Function() onSave,
}) {
  return showDialog<PracticeTemplate>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('テンプレートを選択'),
            content: templates.isEmpty
                ? const Text('保存されているテンプレートがありません')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];

                        return ListTile(
                          title: Text(template.name),
                          subtitle: Text(
                            '${template.type} / ${template.startTime} / ${template.durationMinutes}分',
                          ),
                          onTap: () {
                            Navigator.of(context).pop(template);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('テンプレートを削除'),
                                    content: Text('「${template.name}」を削除しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text('削除'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldDelete != true) return;

                              templates.removeAt(index);
                              onChanged();
                              await onSave();

                              setDialogState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    },
  );
}
