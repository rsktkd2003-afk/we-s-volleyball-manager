import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/utils/notification_session_guard.dart';

void main() {
  group('NotificationSessionGuard', () {
    test('同じ世代とuidのセッションだけを有効と判定する', () {
      final guard = NotificationSessionGuard();
      final session = guard.capture('user-a');

      expect(guard.isCurrent(session, 'user-a'), isTrue);
      expect(guard.isCurrent(session, 'user-b'), isFalse);
      expect(guard.isCurrent(session, null), isFalse);
    });

    test('ログアウト後は過去のセッションを無効化する', () {
      final guard = NotificationSessionGuard();
      final oldSession = guard.capture('user-a');

      guard.invalidate();
      final newSession = guard.capture('user-b');

      expect(guard.isCurrent(oldSession, 'user-a'), isFalse);
      expect(guard.isCurrent(oldSession, 'user-b'), isFalse);
      expect(guard.isCurrent(newSession, 'user-b'), isTrue);
    });
  });
}
