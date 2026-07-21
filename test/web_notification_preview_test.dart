import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('本番のFlutter Service Workerと通知プレビューのスコープを分離する', () {
    final indexHtml = File('web/index.html').readAsStringSync();

    expect(
      indexHtml,
      contains('{ scope: "firebase-cloud-messaging-push-scope" }'),
    );
    expect(indexHtml, contains('worker.state !== "activated"'));
    expect(indexHtml, contains('if (!registration.active)'));
  });
}
