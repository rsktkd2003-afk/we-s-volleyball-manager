import 'package:flutter/material.dart';

Widget sectionTitle(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}

DropdownButtonFormField<String> textDropdown({
  required String value,
  required String label,
  required List<String> items,
  required ValueChanged<String> onChanged,
}) {
 final user = FirebaseAuth.instance.currentUser;
final myName = user?.displayName ?? user?.email ?? 'ログインユーザー';

ListTile(
  leading: const Icon(Icons.person),
  title: const Text('回答者'),
  subtitle: Text(myName),
)
}

Widget timeDropdownRow({
  required String hour,
  required String minute,
  required List<String> hourOptions,
  required List<String> minuteOptions,
  required ValueChanged<String> onHourChanged,
  required ValueChanged<String> onMinuteChanged,
}) {
  return Row(
    children: [
      Expanded(
        child: textDropdown(
          value: hour,
          label: '時',
          items: hourOptions,
          onChanged: onHourChanged,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: textDropdown(
          value: minute,
          label: '分',
          items: minuteOptions,
          onChanged: onMinuteChanged,
        ),
      ),
    ],
  );
}