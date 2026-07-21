import 'notification_preview_stub.dart'
    if (dart.library.js_interop) 'notification_preview_web.dart'
    as implementation;

Future<void> showLocalNotificationPreview() {
  return implementation.showLocalNotificationPreview();
}
