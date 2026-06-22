import 'package:flutter/material.dart';

Future<bool?> showSaveTemplateDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('テンプレートとして保存しますか?'),
        content: const Text(
          'この練習内容をテンプレートとして保存しますか',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('はい'),
          ),
        ],
      );
    },
  );
}