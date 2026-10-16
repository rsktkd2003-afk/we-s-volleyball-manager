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

/// players の Fake。Firestore と同様に、書き込みは発行した時点で購読中の
/// ストリームへ反映し(レイテンシ補償)、サーバーが拒否した場合は元に戻す。
class FakePlayerRepository implements PlayerRepository {
  final _streams = _Streams<List<Player>>();

  /// 購読中のストリームへ最後に流れた一覧。
  List<Player>? _latest;

  List<StreamController<List<Player>>> get controllers => _streams.controllers;
  StreamController<List<Player>> get last => _streams.last;
  bool get hasActiveListener => _streams.hasActiveListener;

  @override
  Stream<List<Player>> watchPlayers() {
    return _streams.open().map((players) => _latest = players);
  }

  /// 書き込みの呼び出し記録(実際のFirestoreには書き込まない)。
  final List<Player> updatedPlayers = [];

  /// 実際に書き込まれるフィールド(部分更新の内容)。
  final List<Map<String, dynamic>> updatedFields = [];
  final List<String> deletedPlayerIds = [];

  /// 設定すると、次の書き込みをこのエラーで失敗させる(1回で解除)。
  Object? nextUpdateError;
  Object? nextDeleteError;

  /// 設定すると、サーバーの応答をこの Future の完了まで保留する
  /// (オフライン等で書き込みが完了しない状況の検証用)。
  Completer<void>? updateGate;
  Completer<void>? deleteGate;

  void _emitLocal(List<Player> players) {
    if (_streams.controllers.isEmpty) return;
    final controller = _streams.last;
    if (!controller.isClosed) controller.add(players);
  }

  @override
  Future<void> updateEditableFields(Player player) async {
    final fields = player.toEditableJson();
    updatedPlayers.add(player);
    updatedFields.add(fields);

    final before = _latest;
    if (before != null) {
      _emitLocal([
        for (final current in before)
          current.id == player.id
              ? Player.fromJson(
                  {...current.toJson(), ...fields},
                  id: current.id,
                )
              : current,
      ]);
    }

    await updateGate?.future;
    final error = nextUpdateError;
    nextUpdateError = null;
    if (error != null) {
      if (before != null) _emitLocal(before);
      throw error;
    }
  }

  @override
  Future<void> deletePlayer(String playerId) async {
    deletedPlayerIds.add(playerId);

    final before = _latest;
    if (before != null) {
      _emitLocal([
        for (final current in before)
          if (current.id != playerId) current,
      ]);
    }

    await deleteGate?.future;
    final error = nextDeleteError;
    nextDeleteError = null;
    if (error != null) {
      if (before != null) _emitLocal(before);
      throw error;
    }
  }
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

/// FirebaseAuth.authStateChanges() と同様に、購読開始時に現在の状態を流す。
class FakeAuthStream {
  final _controller = StreamController<String?>.broadcast();
  bool _hasValue = false;
  String? _value;

  void add(String? uid) {
    _hasValue = true;
    _value = uid;
    _controller.add(uid);
  }

  void addError(Object error) => _controller.addError(error);

  bool get hasListener => _controller.hasListener;

  Stream<String?> get stream => Stream<String?>.multi((listener) {
        if (_hasValue) listener.add(_value);
        final sub = _controller.stream.listen(
          listener.add,
          onError: listener.addError,
        );
        listener.onCancel = sub.cancel;
      });
}

class FakeCurrentUserRepository implements CurrentUserRepository {
  final auth = FakeAuthStream();
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
