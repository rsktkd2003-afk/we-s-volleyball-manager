import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/utils/async_serial_queue.dart';

void main() {
  test('追加された非同期処理を1件ずつ実行する', () async {
    final queue = AsyncSerialQueue();
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    final order = <String>[];

    final first = queue.add(() async {
      order.add('first-start');
      firstStarted.complete();
      await releaseFirst.future;
      order.add('first-end');
    });

    await firstStarted.future;

    final second = queue.add(() async {
      order.add('second');
    });

    await Future<void>.delayed(Duration.zero);
    expect(order, ['first-start']);

    releaseFirst.complete();
    await Future.wait([first, second]);

    expect(order, ['first-start', 'first-end', 'second']);
  });

  test('先行処理が失敗しても後続処理を実行する', () async {
    final queue = AsyncSerialQueue();
    var completed = false;

    await expectLater(
      queue.add(() async => throw StateError('failure')),
      throwsStateError,
    );

    await queue.add(() async {
      completed = true;
    });

    expect(completed, isTrue);
  });
}
