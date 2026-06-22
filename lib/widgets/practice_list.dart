import 'package:flutter/material.dart';

import '../models/practice.dart';

class PracticeList extends StatelessWidget {
  final List<Practice> practices;
  final void Function(int index) onDelete;

  const PracticeList({
    super.key,
    required this.practices,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: practices.length,
      itemBuilder: (context, index) {
        final practice = practices[index];

        return ListTile(
          leading: const Icon(Icons.event),
          title: Text('${practice.date} / ${practice.type}'),
          subtitle: Text(
            '${practice.startTime}開始 / ${practice.durationMinutes}分',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('削除確認'),
                    content: const Text('この予定を削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('削除'),
                      ),
                    ],
                  );
                },
              );

              if (result == true) {
                onDelete(index);
              }
            },
          ),
        );
      },
    );
  }
}