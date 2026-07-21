import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/app_notification_status.dart';

void main() {
  group('AppNotificationStatus', () {
    test('通知許可とトークンが揃うと有効になる', () {
      const status = AppNotificationStatus(
        preferenceEnabled: true,
        permission: AppNotificationPermission.authorized,
        tokenAvailable: true,
      );

      expect(status.isActive, isTrue);
      expect(status.permissionLabel, '許可済み');
      expect(status.description, 'この端末で通知を受け取れます。');
    });

    test('端末設定がオフなら許可済みでも無効になる', () {
      const status = AppNotificationStatus(
        preferenceEnabled: false,
        permission: AppNotificationPermission.authorized,
        tokenAvailable: true,
      );

      expect(status.isActive, isFalse);
      expect(status.description, 'この端末への通知は停止中です。');
    });

    test('通知拒否と未対応環境を区別する', () {
      const denied = AppNotificationStatus(
        preferenceEnabled: true,
        permission: AppNotificationPermission.denied,
        tokenAvailable: false,
      );
      const unavailable = AppNotificationStatus(
        preferenceEnabled: true,
        permission: AppNotificationPermission.unavailable,
        tokenAvailable: false,
      );

      expect(denied.isActive, isFalse);
      expect(denied.canChange, isTrue);
      expect(denied.permissionLabel, '拒否');
      expect(unavailable.canChange, isFalse);
      expect(unavailable.permissionLabel, '利用不可');
    });
  });
}
