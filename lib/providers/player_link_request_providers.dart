import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_user_doc.dart';
import '../models/player_link_request.dart';
import '../repositories/player_link_request_repository.dart';
import 'current_user_providers.dart';

final playerLinkRequestRepositoryProvider =
    Provider<PlayerLinkRequestRepository>((ref) {
  return FirebasePlayerLinkRequestRepository();
});

/// ログイン中ユーザーが管理者か。users/{uid}.role をリアルタイムに反映する。
///
/// 権限が確定しない間は fail-closed とし、管理者として扱わない。
/// - 認証状態・ユーザードキュメントの読み込み中: 読み込み中(値なし)
/// - 未ログイン / ドキュメントなし / role != 'admin': false
/// - 読み取りエラー: エラー
///
/// ログアウト・別ユーザーでのログイン時は currentUserDocProvider と共に
/// 再評価され、以前のユーザーの判定は引き継がれない。
/// 利用側は `maybeWhen(data: ..., orElse: () => false)` のように、
/// data 以外(読み込み中・再評価中・エラー)を管理者でないとして扱うこと。
///
/// UI の表示制御用であり、実際の権限は Firestore Rules で制御される。
final currentUserIsAdminProvider = FutureProvider.autoDispose<bool>((ref) {
  final userDoc = ref.watch(currentUserDocProvider);

  return userDoc.when(
    data: (state) => state is CurrentUserDocLoaded && state.user.isAdmin,
    error: (error, stackTrace) => Future<bool>.error(error, stackTrace),
    // 権限が確定するまで完了しない Future を返し、読み込み中のままにする。
    loading: () => Completer<bool>().future,
  );
});

/// 管理者専用操作の直前に呼び、最新の権限が管理者であることを確認する。
/// 判定できない場合(読み込み失敗など)は false を返す(fail-closed)。
Future<bool> confirmCurrentUserIsAdmin(WidgetRef ref) async {
  try {
    return await ref.read(currentUserIsAdminProvider.future);
  } catch (_) {
    return false;
  }
}

final pendingPlayerLinkRequestsProvider =
    StreamProvider.autoDispose<List<PlayerLinkRequest>>((ref) {
  final repository = ref.watch(playerLinkRequestRepositoryProvider);
  return repository.watchPendingRequests();
});
