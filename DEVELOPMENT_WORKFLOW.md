# Development Workflow

## 基本フロー

1. `main`を最新にする。
2. 作業用ブランチを作成する。
3. 変更範囲と関連コードを確認する。
4. 必要最小限の変更を実装する。
5. 解析とビルドを実行する。
6. 差分を確認してPull Requestを作成する。
7. CI成功後にSquash mergeする。
8. デプロイは別操作として、明示的な許可後に行う。

## ブランチ

```powershell
git switch main
git pull --ff-only
git switch -c feature/<short-name>
```

同じブランチを複数のAIに同時編集させない。

## ローカル確認

```powershell
flutter pub get
flutter analyze
flutter build web
git status
git diff
```

`test/widget_test.dart`は現在Flutter初期テンプレートのCounterテストであり、アプリに合わせて修正するまではCIの必須チェックに含めない。修正後は`flutter test`を必須確認へ追加する。

## Firebase

- Firebase HostingへのデプロイはPull Requestのマージとは分ける。
- デプロイ前に対象Firebaseプロジェクトを確認する。
- 認証、Firestoreの構造や権限、セキュリティルールを推測で変更しない。
- 秘密情報や環境固有ファイルをコミットしない。
