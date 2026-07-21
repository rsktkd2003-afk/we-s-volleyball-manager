import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('ログアウト'),
      content: const Text('ログアウトしますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text('ログアウト'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
