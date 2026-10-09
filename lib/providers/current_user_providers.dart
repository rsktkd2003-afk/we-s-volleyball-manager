import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_user_doc.dart';
import '../repositories/current_user_repository.dart';
import 'cancelable_stream_provider.dart';

final currentUserRepositoryProvider = Provider<CurrentUserRepository>((ref) {
  return FirebaseCurrentUserRepository();
});

/// ログイン中ユーザーの uid。未ログインなら null。
final authUidProvider = cancelableStreamProvider<String?>((ref) {
  final repository = ref.watch(currentUserRepositoryProvider);
  return repository.watchAuthUid();
});

/// users/{uid} をリアルタイムに監視する。
///
/// - 認証状態の確定前: 読み込み中
/// - 未ログイン: [CurrentUserSignedOut]
/// - ドキュメントなし: [CurrentUserDocMissing]
/// - 取得成功: [CurrentUserDocLoaded]（role / playerId の更新を即時反映）
/// - 認証状態・ユーザードキュメントの読み取りエラー: AsyncValue.error
///
/// uid が変わる(ログアウト・別ユーザーでログイン)と再構築され、以前の
/// users/{uid} の購読は即座に解除される。再構築中は以前のユーザーの値を
/// 引き継がず読み込み中になる。
final currentUserDocProvider =
    cancelableStreamProvider<CurrentUserDocState>((ref) {
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
