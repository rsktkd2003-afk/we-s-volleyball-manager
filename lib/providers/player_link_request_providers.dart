import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_link_request.dart';
import '../repositories/player_link_request_repository.dart';
import '../services/firestore_service.dart';

final playerLinkRequestRepositoryProvider =
    Provider<PlayerLinkRequestRepository>((ref) {
  return FirebasePlayerLinkRequestRepository();
});

final currentUserIsAdminProvider = FutureProvider<bool>((ref) {
  return FirestoreService.isCurrentUserAdmin();
});

final pendingPlayerLinkRequestsProvider =
    StreamProvider<List<PlayerLinkRequest>>((ref) {
  final repository = ref.watch(playerLinkRequestRepositoryProvider);
  return repository.watchPendingRequests();
});
