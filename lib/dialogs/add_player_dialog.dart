import 'package:flutter/material.dart';

Future<String?> showAddPlayerDialog(BuildContext context) async {
  final nameController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add Player'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Player name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, nameController.text);
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}
