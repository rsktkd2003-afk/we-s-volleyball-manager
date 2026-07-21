class NotificationSession {
  const NotificationSession({
    required this.uid,
    required this.generation,
  });

  final String uid;
  final int generation;
}

class NotificationSessionGuard {
  int _generation = 0;

  NotificationSession capture(String uid) {
    return NotificationSession(uid: uid, generation: _generation);
  }

  void invalidate() {
    _generation++;
  }

  bool isCurrent(NotificationSession session, String? currentUid) {
    return session.generation == _generation && session.uid == currentUid;
  }
}
