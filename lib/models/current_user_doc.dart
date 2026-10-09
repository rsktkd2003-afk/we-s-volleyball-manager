/// users/{uid} ドキュメントの内容。
class CurrentUserDoc {
  const CurrentUserDoc({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.playerId,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? playerId;

  bool get isAdmin => role == 'admin';

  bool get hasLinkedPlayer => playerId != null && playerId!.isNotEmpty;

  /// main.dart の既存判定と同じく、role 未設定は 'member' として扱う。
  factory CurrentUserDoc.fromJson(String uid, Map<String, dynamic> json) {
    return CurrentUserDoc(
      uid: uid,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      playerId: json['playerId'] as String?,
    );
  }
}

/// ログイン中ユーザーのドキュメント状態。
/// 読み取りエラーは AsyncValue.error として別に扱う。
sealed class CurrentUserDocState {
  const CurrentUserDocState();
}

/// 未ログイン(ログアウト後を含む)。
class CurrentUserSignedOut extends CurrentUserDocState {
  const CurrentUserSignedOut();
}

/// ログイン済みだが users/{uid} が存在しない。
class CurrentUserDocMissing extends CurrentUserDocState {
  const CurrentUserDocMissing(this.uid);

  final String uid;
}

/// ログイン済みで users/{uid} を取得できた。
class CurrentUserDocLoaded extends CurrentUserDocState {
  const CurrentUserDocLoaded(this.user);

  final CurrentUserDoc user;
}
