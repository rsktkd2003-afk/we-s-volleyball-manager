import 'dart:js_interop';

@JS('showWesTestNotification')
external JSPromise<JSAny?> _showWesTestNotification();

Future<void> showLocalNotificationPreview() async {
  await _showWesTestNotification().toDart;
}
