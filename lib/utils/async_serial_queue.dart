class AsyncSerialQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> add(Future<void> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>(
      (_) {},
      onError: (_, _) {},
    );
    return next;
  }
}
