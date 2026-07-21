enum AppNotificationPermission {
  notDetermined,
  denied,
  authorized,
  provisional,
  unavailable,
}

class AppNotificationStatus {
  const AppNotificationStatus({
    required this.preferenceEnabled,
    required this.permission,
    required this.tokenAvailable,
  });

  final bool preferenceEnabled;
  final AppNotificationPermission permission;
  final bool tokenAvailable;

  bool get isActive {
    final permissionGranted =
        permission == AppNotificationPermission.authorized ||
        permission == AppNotificationPermission.provisional;

    return preferenceEnabled && permissionGranted && tokenAvailable;
  }

  bool get canChange => permission != AppNotificationPermission.unavailable;

  String get permissionLabel {
    switch (permission) {
      case AppNotificationPermission.notDetermined:
        return '未許可';
      case AppNotificationPermission.denied:
        return '拒否';
      case AppNotificationPermission.authorized:
        return '許可済み';
      case AppNotificationPermission.provisional:
        return '一時許可';
      case AppNotificationPermission.unavailable:
        return '利用不可';
    }
  }

  String get description {
    if (!preferenceEnabled) {
      return 'この端末への通知は停止中です。';
    }

    switch (permission) {
      case AppNotificationPermission.notDetermined:
        return '通知の許可がまだ選択されていません。';
      case AppNotificationPermission.denied:
        return 'ブラウザまたは端末の設定で通知が拒否されています。';
      case AppNotificationPermission.authorized:
        return tokenAvailable
            ? 'この端末で通知を受け取れます。'
            : '通知トークンを登録できませんでした。';
      case AppNotificationPermission.provisional:
        return tokenAvailable
            ? 'この端末で通知が一時許可されています。'
            : '通知トークンを登録できませんでした。';
      case AppNotificationPermission.unavailable:
        return 'この環境では通知設定を利用できません。';
    }
  }
}
