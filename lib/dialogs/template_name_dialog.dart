import 'package:flutter/material.dart';

Future<String?> showTemplateNameDialog(BuildContext context) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Template Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Example: Thursday Practice',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
