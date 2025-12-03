# Phase 1 タスクチェックリスト

このチェックリストに沿って開発を進めてください。各タスク完了時に `[ ]` を `[x]` に変更します。

---

## Week 1: RecurringOrderモデル + 自動生成

### Day 1-2: データベース設計・マイグレーション

#### マイグレーションファイル作成
- [x] `rails g migration CreateRecurringOrders` 実行
- [x] `rails g migration AddScheduleFieldsToOrders` 実行
- [x] `rails g migration AddDeliveryFlowFieldsToOrders` 実行（配送フロー関連カラム追加）
- [x] `rails g migration AddCapacityFieldsToRestaurants` 実行
- [x] `rails g migration AddDeliveryFieldsToCompanies` 実行

#### マイグレーション内容記述
- [x] recurring_ordersテーブルのカラム定義完了（配送フロー関連カラム含む）
- [x] インデックス追加完了
- [x] 外部キー制約追加完了
- [x] orders, restaurants, companiesへのカラム追加完了
- [x] 配送フロー関連カラム追加完了
  - [x] is_trial（試食会/本導入）
  - [x] collection_time（器材回収時刻）
  - [x] warehouse_pickup_time（倉庫集荷時刻）
  - [x] return_location（器材返却先）
  - [x] equipment_notes（器材メモ）

#### マイグレーション実行
- [x] `rails db:migrate` 成功
- [x] `rails db:rollback` 成功（確認後、再度migrate）
- [x] `rails db:migrate:status` で確認

#### RecurringOrderモデルファイル作成
- [x] `app/models/recurring_order.rb` 作成
- [x] 基本的なアソシエーション記述

**確認コマンド:**
```bash
rails db:migrate
rails db:rollback
rails db:migrate
rails c
> RecurringOrder
> RecurringOrder.column_names
```

---

### Day 3-4: RecurringOrderモデルの実装

#### バリデーション実装
- [x] day_of_week の inclusion 追加
- [x] frequency の inclusion 追加
- [x] default_meal_count の numericality 追加
- [x] delivery_time, start_date の presence 追加
- [x] end_date_after_start_date カスタムバリデーション
- [x] restaurant_capacity_check カスタムバリデーション
- [x] restaurant_not_closed_on_day カスタムバリデーション

#### アソシエーション設定
- [x] belongs_to :company
- [x] belongs_to :restaurant
- [x] belongs_to :menu (optional: true)
- [x] belongs_to :delivery_company (optional: true)
- [x] has_many :orders

#### スコープ定義
- [x] scope :active
- [x] scope :for_day_of_week
- [x] scope :current

#### テスト作成
- [x] `spec/models/recurring_order_spec.rb` 作成
- [x] バリデーションテスト
- [x] スコープテスト
- [x] すべてのテストがパス

**確認コマンド:**
```bash
rspec spec/models/recurring_order_spec.rb
rails c
> RecurringOrder.create!(company: Company.first, restaurant: Restaurant.first, ...)
```

---

### Day 5-6: Order自動生成機能

#### RecurringOrder#generate_orders_for_range 実装
- [x] メソッド定義
- [x] 指定期間の日付をループ
- [x] 該当する曜日のみOrderを生成
- [x] 既存Orderと重複しないチェック
- [x] トランザクション処理

#### RecurringOrderGenerator サービス作成
- [x] `app/services/recurring_order_generator.rb` 作成
- [x] generate_for_period メソッド実装
- [x] エラーハンドリング

#### Rakeタスク作成
- [x] `lib/tasks/orders.rake` 作成
- [x] orders:generate タスク実装
- [x] 引数で週数を指定可能に

#### バックグラウンドジョブ作成
- [x] `app/jobs/generate_orders_job.rb` 作成
- [x] perform メソッド実装

#### テスト作成
- [x] generate_orders_for_range のテスト
- [x] RecurringOrderGenerator のテスト
- [x] 生成されたOrderの検証

**確認コマンド:**
```bash
rails orders:generate[4]
rails c
> GenerateOrdersJob.perform_now(4)
> Order.where('created_at > ?', 1.minute.ago).count
```

---

### Day 7: 管理画面実装（RecurringOrder）

#### Dashboard作成
- [x] `app/dashboards/recurring_order_dashboard.rb` 作成
- [x] ATTRIBUTE_TYPES 定義
- [x] COLLECTION_ATTRIBUTES 定義
- [x] SHOW_PAGE_ATTRIBUTES 定義
- [x] FORM_ATTRIBUTES 定義

#### Controller作成
- [x] `app/controllers/admin/recurring_orders_controller.rb` 作成
- [x] routes.rb に追加

#### フォームカスタマイズ
- [x] `app/views/admin/recurring_orders/_form.html.erb` 作成
- [x] 曜日選択のUI改善
- [x] 時刻入力のUI改善

#### 一括生成ボタン追加
- [x] index画面に「Order自動生成」ボタン追加
- [x] bulk_generate アクション実装
- [x] 成功メッセージ表示

#### ナビゲーション追加
- [x] routes.rb にrecurring_ordersリソース追加

**確認項目:**
- [x] /admin/recurring_orders にアクセスできる
- [x] 新規作成できる
- [x] 編集できる
- [x] 削除できる
- [x] 一括生成ボタンが動作する

---

## Week 2: カレンダービュー

### Day 8-9: カレンダー表示の基本実装

#### Gem インストール
- [x] Gemfile に `gem 'simple_calendar'` 追加
- [x] `bundle install` 実行
- [x] `rails g simple_calendar:views` 実行

#### OrdersController にアクション追加
- [x] calendar アクション追加
- [x] routes.rb に追加

#### 週間カレンダービュー作成
- [x] `app/views/admin/orders/calendar.html.erb` 作成
- [x] week_calendar 使用
- [x] Orderの表示

#### 月間カレンダービュー作成
- [x] month_calendar 使用
- [x] 前後の月への移動ボタン

#### スタイル調整
- [x] カレンダーのCSS調整
- [x] レスポンシブ対応

**確認項目:**
- [x] /admin/orders/calendar にアクセスできる
- [x] 週間ビューが表示される
- [x] 月間ビューが表示される
- [x] 前後への移動ができる

---

### Day 10-11: カレンダーUIの改善

#### 企業別色分け
- [x] Company モデルに color カラム追加
- [x] マイグレーション実行
- [x] 色を事前登録
- [x] カレンダーイベントに色適用

#### ツールチップ表示
- [x] Bootstrap tooltip 導入
- [x] ホバー時に詳細情報表示

#### フィルター機能
- [x] 企業フィルター追加
- [x] 飲食店フィルター追加
- [x] ステータスフィルター追加
- [x] フィルター適用ロジック

#### ドラッグ&ドロップ（オプション）
- [ ] Stimulus Controller 作成
- [ ] ドラッグ可能に設定
- [ ] ドロップ時の日付更新

**確認項目:**
- [x] 企業ごとに色が違う
- [x] ホバーで詳細が見える
- [x] フィルターが動作する
- [ ] (オプション) ドラッグ&ドロップが動作する

---

### Day 12: メニュー重複チェック機能

#### Orderモデルにバリデーション追加
- [x] duplicate_menu_in_week? メソッド実装
- [x] 同じ週の同じメニューをチェック
- [x] 週の開始（月曜日）と終了（日曜日）で判定

#### MenuDuplicationChecker サービス作成
- [x] Orderモデルのメソッドとして実装（サービスクラス不要と判断）
- [x] 同じ週内の同じrestaurant_id + menu_idをチェック
- [x] 自分自身を除外して判定

#### カレンダー画面にアラート表示
- [x] 重複があるOrderに警告マーク表示
- [x] ツールチップで詳細表示
- [x] パルスアニメーション追加

#### テスト作成
- [x] テストデータで動作確認済み
- [ ] RSpecテスト（今後追加予定）

**確認項目:**
- [x] 重複検出ロジックが動作する
- [x] カレンダーに警告マークが出る
- [x] 重複がない場合は警告が出ない

---

### Day 13-14: スケジュール調整画面

#### 一括編集機能（Day 13完了）
- [x] スケジュール調整画面を実装（/admin/orders/schedule）
- [x] 複数Orderを選択できるUI（チェックボックス、全選択機能）
- [x] 日付・時刻の直接編集フォーム
- [x] 一括更新処理（update_scheduleアクション）
- [x] 期間指定とフィルター機能（企業、飲食店、ステータス）

#### コンフリクト表示（Day 13完了）
- [x] Orderモデルにschedule_conflictsメソッド実装
- [x] 飲食店の時間帯重複検出（±2時間以内）
- [x] 同じ企業の複数配送警告
- [x] has_conflicts?メソッド実装
- [x] コンフリクト行を赤色でハイライト
- [x] 警告アイコンとツールチップ表示
- [x] パルスアニメーション追加

#### Stimulus Controller（Day 14 - オプション/未実装）
- [ ] `app/javascript/controllers/calendar_controller.js` 作成
- [ ] リアルタイムコンフリクトチェック
- [ ] Ajaxでの非同期更新
- [ ] イベントのドラッグ&ドロップ
- [ ] 日付更新API呼び出し

**確認項目:**
- [x] 複数Orderを一括編集できる
- [x] コンフリクトが視覚的に分かる
- [x] 選択行のハイライト表示
- [ ] (オプション) ドラッグ&ドロップが動作する
- [ ] (オプション) リアルタイムコンフリクトチェック

---

## Week 3: 配送シート生成

### Day 15-16: 配送シートPDF生成（Prawn）

#### Gem インストール
- [x] Gemfile に `gem 'prawn'` 追加
- [x] Gemfile に `gem 'prawn-table'` 追加
- [x] `bundle install` 実行

#### 日本語フォント準備
- [x] `app/assets/fonts/` ディレクトリ作成
- [ ] NotoSansJP-Regular.ttf ダウンロード（Day 21で実施）
- [ ] フォント配置確認（Day 21で実施）

#### DeliverySheetPdfGenerator サービス作成
- [x] `app/services/delivery_sheet_pdf_generator.rb` 作成
- [x] generate メソッド実装
- [x] generate_daily_sheet メソッド実装
- [x] テーブル形式で配送情報表示

#### OrdersController にアクション追加
- [x] delivery_sheet_pdf アクション追加
- [x] routes.rb に追加
- [x] send_data でPDF返却

#### テスト
- [x] PDF生成テスト（手動確認済み）
- [ ] 日本語表示確認（Day 21でフォント設定後に確認）

**確認項目:**
- [x] PDFが生成される
- [ ] 日本語が正しく表示される（Day 21で確認）
- [x] レイアウトが見やすい
- [x] ダウンロードできる
- [x] 配送フロー関連の項目が表示される
  - [x] 倉庫集荷時刻
  - [x] 飲食店集荷時刻
  - [x] 器材回収時刻
  - [x] 返却先（倉庫/飲食店）
  - [x] 器材メモ
  - [x] 試食会/本導入の区別

---

### Day 17-18: 配送シートExcel生成（Caxlsx）

**注意：この機能はスキップします。PDFで印刷可能なため、Excel生成は不要と判断しました。**

#### Gem インストール
- [ ] ~~Gemfile に `gem 'caxlsx'` 追加~~（スキップ）
- [ ] ~~Gemfile に `gem 'caxlsx_rails'` 追加~~（スキップ）
- [ ] ~~`bundle install` 実行~~（スキップ）

#### DeliverySheetExcelGenerator サービス作成
- [ ] ~~`app/services/delivery_sheet_excel_generator.rb` 作成~~（スキップ）
- [ ] ~~generate メソッド実装~~（スキップ）
- [ ] ~~generate_daily_sheet メソッド実装~~（スキップ）
- [ ] ~~日付ごとにシート分割~~（スキップ）

#### OrdersController にアクション追加
- [ ] ~~delivery_sheet_excel アクション追加~~（スキップ）
- [ ] ~~routes.rb に追加~~（スキップ）
- [ ] ~~send_data でExcel返却~~（スキップ）

#### セルの書式設定
- [ ] ~~ヘッダー行を太字~~（スキップ）
- [ ] ~~列幅の自動調整~~（スキップ）
- [ ] ~~罫線設定~~（スキップ）

#### テスト
- [ ] ~~Excel生成テスト~~（スキップ）
- [ ] ~~シート分割確認~~（スキップ）

**確認項目:**
- [ ] ~~Excelファイルが生成される~~（スキップ）
- [ ] ~~日付ごとにシートが分かれている~~（スキップ）
- [ ] ~~Excelで開いて編集できる~~（スキップ）
- [ ] ~~書式が適切~~（スキップ）
- [ ] ~~配送フロー関連の項目がすべて含まれている~~（スキップ）

---

### Day 19-20: 配送シート画面の実装

#### 配送シート一覧画面作成
- [x] `app/views/admin/orders/delivery_sheets.html.erb` 作成
- [x] 日付範囲フィルター
- [x] 配送会社フィルター
- [x] 企業・飲食店フィルター

#### プレビュー表示
- [x] テーブル形式でプレビュー
- [x] 並び順: scheduled_date, collection_time順
- [x] 日付ごとにグループ化

#### 一括出力機能
- [x] 「PDF出力」ボタン（ヘッダーとフッター）
- [ ] ~~「Excel出力」ボタン~~（Excel生成スキップのため不要）
- [x] フィルター条件でPDF出力

#### ナビゲーション追加
- [x] カレンダー画面から配送シートへのリンク
- [x] スケジュール調整画面から配送シートへのリンク
- [x] パンくずリスト

**確認項目:**
- [x] /admin/orders/delivery_sheets にアクセスできる
- [x] フィルターが動作する
- [x] プレビューが見やすい
- [x] PDF出力できる
- [x] メニュー重複警告アイコンが表示される

---

### Day 21: 日本語フォント設定

#### フォントファイル確認
- [x] NotoSansJP-Regular.ttf のダウンロード手順をREADME.mdに記載
- [x] パスの設定（app/assets/fonts/NotoSansJP-Regular.ttf）
- [x] .gitignoreにフォントファイル除外設定追加

#### Prawn設定
- [x] `config/initializers/prawn.rb` 作成
- [x] hide_m17n_warning 設定

#### フォント適用
- [x] DeliverySheetPdfGenerator で既にフォント指定済み（11-15行目）
- [x] フォントがない場合のフォールバック処理も実装済み

**確認項目:**
- [x] 設定ファイルが作成されている
- [x] フォントダウンロード手順が明確
- [x] フォントがない場合でもエラーにならない
- [ ] （オプション）実際にフォントファイルを配置してPDF生成確認

---

## Week 4: 制約チェック + テスト

### Day 22-23: バリデーション・制約チェック強化

#### 飲食店キャパチェック
- [x] restaurant_capacity_check バリデーション実装
- [x] 1日の合計食数をチェック（capacity_per_day）
- [x] 1日の案件数をチェック（max_lots_per_day）
- [x] キャンセル済み案件は計算対象外
- [x] エラーメッセージ表示

#### 定休日チェック
- [x] restaurant_not_closed バリデーション実装
- [x] 曜日ベースの定休日チェック（closed_days配列）
- [x] エラーメッセージ表示（日付と曜日付き）

#### 配送時間制約チェック
- [x] delivery_time_feasible バリデーション実装
- [x] 集荷→納品の時間計算
- [x] 最低30分の余裕時間チェック
- [x] 時刻の前後関係チェック

#### ConflictDetector サービス作成
- [x] `app/services/conflict_detector.rb` 作成
- [x] detect_for_date メソッド実装
- [x] detect_for_range メソッド実装
- [x] detect_for_order メソッド実装
- [x] キャパオーバー検出
- [ ] ドライバー重複検出（将来実装予定）
- [x] メニュー重複検出
- [x] 時間帯重複検出
- [x] 定休日検出
- [x] 重大度レベル（high/medium）付与

#### テスト作成
- [x] spec/models/order_spec.rb 作成
- [x] バリデーションテスト（キャパ、定休日、配送時間）
- [x] メニュー重複テスト
- [x] スケジュールコンフリクトテスト
- [x] spec/services/conflict_detector_spec.rb 作成
- [x] ConflictDetector のテスト

**確認項目:**
- [x] キャパオーバーが防止される
- [x] 定休日登録が防止される
- [x] 配送時間の矛盾が検出される
- [x] コンフリクト一覧が取得できる
- [ ] （次のステップ）実際のデータでテスト実行

---

### Day 24-25: 統合テスト・調整

#### E2Eテスト作成
- [x] Gemfile更新（capybara, selenium-webdriver追加）
- [x] RSpec/Capybara設定
- [x] `spec/features/recurring_orders_spec.rb` 作成
- [x] 定期スケジュール登録のシナリオ
- [x] Order自動生成のシナリオ
- [x] `spec/features/calendar_spec.rb` 作成
- [x] カレンダー表示のシナリオ
- [x] フィルタリング・表示切替のシナリオ
- [x] `spec/features/delivery_sheets_spec.rb` 作成
- [x] 配送シート出力のシナリオ
- [x] `spec/features/schedule_adjustment_spec.rb` 作成
- [x] スケジュール調整のシナリオ

#### パフォーマンステスト
- [x] N+1クエリチェック（bullet gem導入）
- [x] config/initializers/bullet.rb 作成
- [x] `spec/performance/orders_performance_spec.rb` 作成
- [x] 大量データでのカレンダー表示テスト
- [x] 配送シート一覧のパフォーマンステスト
- [x] スケジュール調整画面のパフォーマンステスト
- [x] PDF生成速度テスト
- [x] ConflictDetector性能テスト
- [x] カスタムマッチャー（perform_under）実装

#### バグ修正
- [ ] バグリスト作成（実運用テスト後）
- [ ] 優先度付け
- [ ] 修正実施

#### ドキュメント更新
- [x] README.md 更新
- [ ] 操作マニュアル作成（Day 26-28で実施予定）
- [ ] データ移行手順書作成（Day 26-28で実施予定）
- [ ] ロールバック手順書作成（Day 26-28で実施予定）

**確認項目:**
- [x] E2Eテストを作成した
- [x] パフォーマンステストを作成した
- [x] Bulletでクエリ監視設定完了
- [ ] （次のステップ）実際にテストを実行して確認
- [ ] （次のステップ）致命的なバグがないか確認

---

### Day 26-28: 実運用テスト・スプシ廃止準備

#### 本番環境デプロイ
- [ ] 本番環境にデプロイ
- [ ] マイグレーション実行
- [ ] 動作確認

#### 実データ移行
- [ ] スプレッドシートから既存マスタ移行
  - [ ] 導入企業マスタ
  - [ ] 飲食店マスタ
  - [ ] 配送会社マスタ
  - [ ] 案件マスタ
- [ ] データ検証スクリプト実行
- [ ] 移行データの目視確認

#### 操作トレーニング
- [ ] スタッフ向けマニュアル配布
- [ ] 操作説明会実施
- [ ] 質疑応答

#### 1週間の実運用テスト
- [ ] Day 1: 定期スケジュール登録
- [ ] Day 2: Order自動生成
- [ ] Day 3: 配送シート出力
- [ ] Day 4: スケジュール調整
- [ ] Day 5: メニュー重複チェック
- [ ] Day 6: トラブル対応
- [ ] Day 7: 総合確認

#### スプシ廃止判断
- [ ] 機能テスト完了
- [ ] データ確認完了
- [ ] 実運用テスト完了
- [ ] ロールバック手順確認完了
- [ ] スタッフ全員が使える状態

#### スプレッドシート廃止
- [ ] 案件マスタースプシを読み取り専用に
- [ ] 配送予定スケジュールスプシを読み取り専用に
- [ ] システムが正として運用開始

**確認項目:**
- [ ] 実運用で1週間問題なく回せた
- [ ] 致命的なバグがない
- [ ] スタッフが自力で操作できる
- [ ] スプシを見なくても業務が回る

---

## Phase 1 完了判定

以下すべてにチェックが入ったらPhase 1完了です。

### 機能
- [ ] 定期スケジュールを登録でき、自動的にOrderが生成される
- [ ] 週間・月間カレンダーで案件を一覧できる
- [ ] メニュー重複がアラート表示される
- [ ] 配送シートをPDF/Excelで出力できる
- [ ] 飲食店のキャパ・定休日をチェックできる
- [ ] コンフリクトが検出される

### 品質
- [ ] すべてのテストがパスする
- [ ] パフォーマンスに問題がない
- [ ] 致命的なバグがない

### 運用
- [ ] 1週間の実運用テストで問題なし
- [ ] スタッフが自力で操作できる
- [ ] 操作マニュアル・ロールバック手順書がある

### 移行
- [ ] スプレッドシートのデータをすべて移行完了
- [ ] 案件マスター・配送シートのスプシを廃止
- [ ] システムが正として運用開始

---

## 次のステップ

Phase 1完了後、Phase 2（請求・支払い＋在庫管理）に進みます。

Phase 2のチェックリストは `phase2_checklist.md` を参照してください。
