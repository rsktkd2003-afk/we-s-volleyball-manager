import 'package:flutter/material.dart';

Future<String?> showPracticeAddMenuDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('予定を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('テンプレートから追加'),
              onTap: () => Navigator.pop(context, 'template'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('新しく作成'),
              onTap: () => Navigator.pop(context, 'custom'),
            ),
          ],
        ),
      );
    },
  );
}