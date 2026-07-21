String normalizeDisplayName(String value) => value.trim();

String? validateDisplayName(String? value) {
  if (value == null || normalizeDisplayName(value).isEmpty) {
    return 'ユーザーネームを入力してください';
  }

  return null;
}
