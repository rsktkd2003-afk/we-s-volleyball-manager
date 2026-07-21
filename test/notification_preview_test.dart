import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/utils/notification_preview.dart';

void main() {
  test('非Web環境ではローカル通知プレビューを拒否する', () {
    expect(
      showLocalNotificationPreview,
      throwsA(isA<UnsupportedError>()),
    );
  });
}
