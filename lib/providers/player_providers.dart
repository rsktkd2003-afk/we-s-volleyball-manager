import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../repositories/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return FirebasePlayerRepository();
});

/// players コレクション全件。購読者がいなくなると購読を解除する。
final playersProvider = StreamProvider.autoDispose<List<Player>>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return repository.watchPlayers();
});
