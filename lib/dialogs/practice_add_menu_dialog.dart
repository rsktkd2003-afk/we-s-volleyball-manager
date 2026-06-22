import 'package:flutter/material.dart';

Future<String?> showPracticeAddMenuDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add Practice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Template'),
              onTap: () => Navigator.pop(context, 'template'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Custom'),
              onTap: () => Navigator.pop(context, 'custom'),
            ),
          ],
        ),
      );
    },
  );
}