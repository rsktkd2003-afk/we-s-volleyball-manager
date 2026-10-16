import 'package:firebase_core/firebase_core.dart';

/// 選手データの保存・削除の失敗を、利用者向けのメッセージに変換する。
/// 内部情報(エラー詳細・スタックトレース)は表示しない。
String playerOperationErrorMessage(Object error, {required String action}) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return '$actionする権限がありません。管理者に確認してください。';
      case 'unavailable':
        return 'サーバーに接続できませんでした。通信環境を確認して、もう一度お試しください。';
    }
  }

  return '$actionに失敗しました。時間をおいて、もう一度お試しください。';
}
