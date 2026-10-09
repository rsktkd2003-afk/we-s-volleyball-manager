import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream を購読して [AsyncValue] として公開する autoDispose Provider を作る。
///
/// Riverpod 2.6.1 の StreamProvider は、最初の値を受信する前(読み込み中)に
/// 破棄されると、`provider.future` を完了させるために元 Stream の購読解除を
/// 最初のイベントが届くまで遅らせる。Firestore の購読が画面を離れた後も
/// 残らないよう、破棄・再構築の時点で即座に購読を解除する。
///
/// [create] は build 中に同期的に呼ばれるため、その中で `ref.watch` できる。
/// 再構築(依存Providerの変化・invalidate)の際は以前の値を引き継がず
/// 読み込み中から始める。`.future` は提供しない。
AutoDisposeNotifierProvider<CancelableStreamNotifier<T>, AsyncValue<T>>
    cancelableStreamProvider<T>(
  Stream<T> Function(Ref<AsyncValue<T>> ref) create,
) {
  return NotifierProvider.autoDispose<CancelableStreamNotifier<T>,
      AsyncValue<T>>(
    () => CancelableStreamNotifier<T>(create),
  );
}

class CancelableStreamNotifier<T> extends AutoDisposeNotifier<AsyncValue<T>> {
  CancelableStreamNotifier(this._create);

  final Stream<T> Function(Ref<AsyncValue<T>> ref) _create;

  @override
  AsyncValue<T> build() {
    final Stream<T> stream;
    try {
      stream = _create(ref);
    } catch (error, stackTrace) {
      return AsyncError<T>(error, stackTrace);
    }

    final subscription = stream.listen(
      (value) => state = AsyncData<T>(value),
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError<T>(error, stackTrace);
      },
    );
    ref.onDispose(subscription.cancel);

    return AsyncLoading<T>();
  }
}
