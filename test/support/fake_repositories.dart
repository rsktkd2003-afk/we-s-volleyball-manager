import 'dart:async';

import 'package:volleyball_app/models/player.dart';
import 'package:volleyball_app/models/schedule_template.dart';
import 'package:volleyball_app/models/team_schedule.dart';
import 'package:volleyball_app/repositories/current_user_repository.dart';
import 'package:volleyball_app/repositories/player_repository.dart';
import 'package:volleyball_app/repositories/schedule_repository.dart';

/// 購読ごとに StreamController を作り、購読状態を検査できるようにする。
class _Streams<T> {
  final List<StreamController<T>> controllers = [];

  Stream<T> open() {
    final controller = StreamController<T>();
    controllers.add(controller);
    return controller.stream;
  }

  StreamController<T> get last => controllers.last;

  bool get hasActiveListener => controllers.any((c) => c.hasListener);
}

class FakePlayerRepository implements PlayerRepository {
  final _streams = _Streams<List<Player>>();

  List<StreamController<List<Player>>> get controllers => _streams.controllers;
  StreamController<List<Player>> get last => _streams.last;
  bool get hasActiveListener => _streams.hasActiveListener;

  @override
  Stream<List<Player>> watchPlayers() => _streams.open();
}

class FakeScheduleReadRepository implements ScheduleReadRepository {
  final _schedules = _Streams<List<TeamSchedule>>();
  final _templates = _Streams<List<ScheduleTemplate>>();

  StreamController<List<TeamSchedule>> get schedules => _schedules.last;
  StreamController<List<ScheduleTemplate>> get templates => _templates.last;
  int get scheduleSubscriptionCount => _schedules.controllers.length;
  bool get hasActiveScheduleListener => _schedules.hasActiveListener;
  bool get hasActiveTemplateListener => _templates.hasActiveListener;

  @override
  Stream<List<TeamSchedule>> watchSchedules() => _schedules.open();

  @override
  Stream<List<ScheduleTemplate>> watchTemplates() => _templates.open();
}

class FakeCurrentUserRepository implements CurrentUserRepository {
  final auth = StreamController<String?>.broadcast();
  final Map<String, List<StreamController<Map<String, dynamic>?>>> _docs = {};

  StreamController<Map<String, dynamic>?> docFor(String uid) =>
      _docs[uid]!.last;

  bool hasActiveDocListener(String uid) =>
      (_docs[uid] ?? const []).any((c) => c.hasListener);

  @override
  Stream<String?> watchAuthUid() => auth.stream;

  @override
  Stream<Map<String, dynamic>?> watchUserData(String uid) {
    final controller = StreamController<Map<String, dynamic>?>();
    _docs.putIfAbsent(uid, () => []).add(controller);
    return controller.stream;
  }
}

Player testPlayer({
  required String id,
  required String name,
  int number = 0,
  String position = 'WS',
  String grade = '1年',
}) {
  return Player(
    id: id,
    name: name,
    number: number,
    position: position,
    dominantHand: '右',
    grade: grade,
    height: 170,
    weight: 60,
    standingReach: 220,
    maxReach: 300,
    blockReach: 290,
  );
}
