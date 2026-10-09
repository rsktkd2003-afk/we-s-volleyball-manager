import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_user_doc.dart';
import '../repositories/current_user_repository.dart';

final currentUserRepositoryProvider = Provider<CurrentUserRepository>((ref) {
  return FirebaseCurrentUserRepository();
});

/// ログイン中ユーザーの uid。未ログインなら null。
final authUidProvider = StreamProvider.autoDispose<String?>((ref) {
  final repository = ref.watch(currentUserRepositoryProvider);
  return repository.watchAuthUid();
});

/// users/{uid} をリアルタイムに監視する。
///
/// - 未ログイン: [CurrentUserSignedOut]
/// - ドキュメントなし: [CurrentUserDocMissing]
/// - 取得成功: [CurrentUserDocLoaded]（role / playerId の更新を即時反映）
/// - 読み取りエラー: AsyncValue.error
///
/// uid が変わる(ログアウト・別ユーザーでログイン)と再構築され、
/// 以前の users/{uid} の購読は解除される。
final currentUserDocProvider =
    StreamProvider.autoDispose<CurrentUserDocState>((ref) {
  // ref.watch は build 中に同期的に呼ぶ必要があるため、async* は使わない。
  final auth = ref.watch(authUidProvider);
  final repository = ref.watch(currentUserRepositoryProvider);

  return auth.when(
    // 認証状態が確定するまでは何も流さず、読み込み中のままにする。
    loading: () => const Stream<CurrentUserDocState>.empty(),
    error: (error, stackTrace) =>
        Stream<CurrentUserDocState>.error(error, stackTrace),
    data: (uid) {
      if (uid == null) {
        return Stream.value(const CurrentUserSignedOut());
      }

      return repository.watchUserData(uid).map((data) {
        if (data == null) return CurrentUserDocMissing(uid);
        return CurrentUserDocLoaded(CurrentUserDoc.fromJson(uid, data));
      });
    },
  );
});
