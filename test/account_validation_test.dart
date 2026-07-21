import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/utils/account_validation.dart';

void main() {
  group('validateDisplayName', () {
    test('空文字を拒否する', () {
      expect(validateDisplayName(''), 'ユーザーネームを入力してください');
      expect(validateDisplayName('   '), 'ユーザーネームを入力してください');
      expect(validateDisplayName(null), 'ユーザーネームを入力してください');
    });

    test('入力済みの値を受け入れる', () {
      expect(validateDisplayName('山田 太郎'), isNull);
      expect(validateDisplayName('  山田 太郎  '), isNull);
    });
  });

  test('normalizeDisplayNameが前後の空白を除去する', () {
    expect(normalizeDisplayName('  山田 太郎  '), '山田 太郎');
  });
}
