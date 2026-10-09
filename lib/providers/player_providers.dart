import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../repositories/player_repository.dart';
import 'cancelable_stream_provider.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return FirebasePlayerRepository();
});

/// players コレクション全件。購読者がいなくなると即座に購読を解除する。
final playersProvider = cancelableStreamProvider<List<Player>>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return repository.watchPlayers();
});
