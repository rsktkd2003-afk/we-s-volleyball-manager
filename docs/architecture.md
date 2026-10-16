# 開発時のコード案内

## 対象と変更方針

Flutter／Riverpod 2.6.1／Firebaseの既存構成を維持する。認証、権限、データ形式、デザイン、レスポンシブ境界値は、構造整理だけを理由に変更しない。作業前にAGENTS.md、README.md、DEVELOPMENT_WORKFLOW.mdを読む。

## データの流れ

```text
画面・Widget → Provider → Repository → Firebase
                        ← Stream    ← snapshots
```

これは統一を目指す基本形であり、すべてが移行済みではない。

| 機能 | 主な画面・Widget | Provider／操作先 | 主な既存テスト |
|---|---|---|---|
| 選手一覧・追加・編集・削除 | MembersScreen、PlayerDetailScreen、PlayerEditScreen | player_providers → PlayerRepository | members_screen、player_operation_safety、player_detail_screen、player_edit_input、firebase_player_repository |
| 認証状態・ユーザー文書 | AppShellの権限表示等 | current_user_providers → CurrentUserRepository | current_user_doc_provider、admin_permission |
| 起動ゲート・ログイン・プロフィール | main、LoginScreen、ProfileScreen | SDK直接参照／static AccountService。起動ゲートはProviderと別購読 | account_validation（入力規則のみ） |
| 予定・テンプレート購読 | ScheduleScreen | scheduleReadRepositoryProvider → ScheduleReadRepository。既定値はscheduleRepositoryProviderと共有 | schedule_screen、shared_providers、stream_cancellation |
| 予定・テンプレート・出欠の書き込み | ScheduleScreen、各dialog、ScheduleDetailSheet、ScheduleResponseSection | scheduleRepositoryProvider → ScheduleRepository → FirebaseScheduleRepository | schedule_operations、firebase_schedule_repository（通信は行わない境界テスト） |
| 選手連携・申請 | PlayerLinkScreen、NotificationCenterScreen | player_link_request_providers → PlayerLinkRequestRepository | admin_permission、notification_center_screen（Firebase transactionの検証とは別） |
| 改善点・コメント | PlayerIssueSectionと関連sheet | player_issue_providers → 具象PlayerIssueRepository。UIにもAuth直接参照あり | 実データの改善点操作は未整備 |
| 掲示板・目標・試合投票 | BulletinStickyArea、MatchPoll各画面 | bulletin／match_poll Provider → 具象Repository。UIにもAuth直接参照あり | Firebase連携検証は未整備 |
| 通知・設定 | SettingsScreen、AccountService | static NotificationService → Messaging／Firestore／SharedPreferences | notification_session_guard、async_serial_queue、notification_enable_flow等の補助処理 |

ファイル名はlibとtest配下に対応する。テスト名の記載は存在する範囲の案内であり、機能全体の検証済みを意味しない。

## 選手操作の契約

- 追加：画面でキャンセル・空白を除外し、trimした名前をPlayerRepository.addPlayerへ渡す。
- Firebase実装が従来の初期値を組み立て、自動IDで追加する。ownerUidは呼び出し時のAuth UID（未ログインなら従来どおりnull）。linkedUidはnull、能力・追加パラメータは既存Playerのデフォルトを使う。
- 編集：playerFromEditInputが入力変換とPlayer組み立てを担当。整数・小数の不正値は0、能力値の不正値は5、能力値は1〜10。新しい入力検証は追加していない。
- Firebaseへの更新はPlayer.toEditableJsonだけをupdateへ渡す。ownerUid、linkedUid、jump／power／speed／stamina／gameSenseを更新しない。
- 削除：選手ドキュメントのみを削除する。連携解除や関連データ削除は追加していない。
- 保存・削除はサーバー応答まで成功扱いにしない。画面離脱で書き込みを取り消したとは扱わない。
- Fakeのローカル反映・rollbackはUIテスト用のモデルであり、Firestore SDK実挙動の証明ではない。
- firebase_player_repository_testはFirebase実装を呼び、SDK境界に渡す値をテスト用オブジェクトで捕捉する。実際のSDK通信・Rules評価・オフライン挙動を検証するものではない。

## 予定・テンプレート・出欠の契約

- 読み取り用のScheduleReadRepositoryとProviderは維持し、既存の購読テストの差し替えを継続する。既定の読み書き実装は同じインスタンスを共有する。
- 画面とdialogはstaticメソッドを呼ばず、Provider経由または引数で渡されたScheduleRepositoryを利用する。
- 予定の購読と再取得はstart昇順。繰り返し日付、順次保存、開始前に控えたcreatedBy、テンプレート追加の順序を維持する。
- 編集のtitle・locationは従来どおりtrimしない。開始日時とdurationMinutesから終了日時を計算し、Firebase実装内でTimestampへ変換する。createdByは編集ペイロードに含めない。
- 削除直前のrole取得は単発読み取りを維持する。取得失敗は管理者扱いにせず、作成者の削除は従来どおり可能とする。UIの判定と実際のRules評価は別。
- 出欠保存はusersのdisplayName→AuthのdisplayName→「ログインユーザー」の順で補完し、playerIdが空ならUIDを使う。未ログインの保存・削除は従来どおり何もしない。
- 出欠一覧はScheduleResponseで表示し、FirestoreのQuerySnapshotをUIへ渡さない。StreamBuilderの表示・購読解除方法は維持する。
- 予定・出欠のエラー表示、多重送信抑止、オフライン仕様は変更していない。

## 購読と画面の寿命

- players、schedules、scheduleTemplates、authUid、currentUserDocはcancelableStreamProviderを使用。初回イベント前もdispose／再構築時に解除する。専用テストがあるため、通常のStreamProviderへ安易に戻さない。
- authUid変更時にcurrentUserDocを再購読し、旧ユーザーの値を引き継がない。権限のloading／errorはadminとして扱わない。
- AppShellはタブを初めて開いたときに生成し、IndexedStackで保持する。開いたタブの購読はタブ切替でも維持し、Shell破棄時に解除する設計。
- issue、comments、bulletin、match_pollの一部Providerは非autoDispose。画面離脱だけで解除されるとは見なさず、寿命の追加検証が必要。
- 通知のsession guardと直列queueは、古いユーザーの操作とトークン更新競合への既存対策。リファクタリングで外さない。

## 未接続・旧コード

AppShellのPracticeScreenは練習案のプレースホルダー。PracticeActionsとPracticeCalendarScreenはこの導線から利用されていない。未使用と断定して削除せず、必要な移行・保存仕様を別途確認する。

## 検証

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web
git diff --check
git diff --exit-code pubspec.lock
```

CIはmainへのPR／pushで実行し、Flutter stableを使用。実行時にはSDKバージョンも記録する。変更した機能のテストで局所確認し、最後に上記を実行する。

Firebase adapterとRulesは別途Emulatorで、実際の部分更新、拒否、transaction競合を検証する必要がある。現在のリポジトリにはそのテスト環境が整備されていない。新規依存やRules変更には別の承認が必要。

## 別途判断が必要な既知課題

- playersのRulesは非adminのownerUid変更を禁止しておらず、所有権変更→削除という経路をコード上許容する。権限仕様とEmulatorで照合する。デプロイ中のRulesは未確認。
- 連携済み選手の削除でusers.playerIdの参照が残る。削除禁止／解除／データ保持の仕様を決める必要がある。
- unlinkPlayerのtransactionは文書の存在を確認するが、現在の相互リンク一致は確認しない。
- 申請作成のpending確認と自動ID追加は一つのtransactionではなく、同時申請の一意性は保証しない。
- 選手保存・削除の処理中フラグは画面内に限定され、開き直した画面や別端末での操作は抑止しない。
- 選手追加・予定削除・出欠操作のエラー表示と処理中制御は未整備。今回の境界整理で挙動は変更しない。
- Webのオフライン書き込み保持、タブ終了、再接続時の結果は実環境相当で未検証。
