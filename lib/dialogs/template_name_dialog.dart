import 'package:flutter/material.dart';

Future<String?> showTemplateNameDialog(BuildContext context) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('テンプレート名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '例：木曜練習',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      );
    },
  );
}