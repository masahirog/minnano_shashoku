# Phase 1 タスクチェックリスト

このチェックリストに沿って開発を進めてください。各タスク完了時に `[ ]` を `[x]` に変更します。

---

## Week 1: RecurringOrderモデル + 自動生成

### Day 1-2: データベース設計・マイグレーション

#### マイグレーションファイル作成
- [ ] `rails g migration CreateRecurringOrders` 実行
- [ ] `rails g migration AddScheduleFieldsToOrders` 実行
- [ ] `rails g migration AddDeliveryFlowFieldsToOrders` 実行（配送フロー関連カラム追加）
- [ ] `rails g migration AddCapacityFieldsToRestaurants` 実行
- [ ] `rails g migration AddDeliveryFieldsToCompanies` 実行

#### マイグレーション内容記述
- [ ] recurring_ordersテーブルのカラム定義完了（配送フロー関連カラム含む）
- [ ] インデックス追加完了
- [ ] 外部キー制約追加完了
- [ ] orders, restaurants, companiesへのカラム追加完了
- [ ] 配送フロー関連カラム追加完了
  - [ ] is_trial（試食会/本導入）
  - [ ] collection_time（器材回収時刻）
  - [ ] warehouse_pickup_time（倉庫集荷時刻）
  - [ ] return_location（器材返却先）
  - [ ] equipment_notes（器材メモ）

#### マイグレーション実行
- [ ] `rails db:migrate` 成功
- [ ] `rails db:rollback` 成功（確認後、再度migrate）
- [ ] `rails db:migrate:status` で確認

#### RecurringOrderモデルファイル作成
- [ ] `app/models/recurring_order.rb` 作成
- [ ] 基本的なアソシエーション記述

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
- [ ] day_of_week の inclusion 追加
- [ ] frequency の inclusion 追加
- [ ] default_meal_count の numericality 追加
- [ ] delivery_time, start_date の presence 追加
- [ ] end_date_after_start_date カスタムバリデーション
- [ ] restaurant_capacity_check カスタムバリデーション
- [ ] restaurant_not_closed_on_day カスタムバリデーション

#### アソシエーション設定
- [ ] belongs_to :company
- [ ] belongs_to :restaurant
- [ ] belongs_to :menu (optional: true)
- [ ] belongs_to :delivery_company (optional: true)
- [ ] has_many :orders

#### スコープ定義
- [ ] scope :active
- [ ] scope :for_day_of_week
- [ ] scope :current

#### テスト作成
- [ ] `spec/models/recurring_order_spec.rb` 作成
- [ ] バリデーションテスト
- [ ] スコープテスト
- [ ] すべてのテストがパス

**確認コマンド:**
```bash
rspec spec/models/recurring_order_spec.rb
rails c
> RecurringOrder.create!(company: Company.first, restaurant: Restaurant.first, ...)
```

---

### Day 5-6: Order自動生成機能

#### RecurringOrder#generate_orders_for_range 実装
- [ ] メソッド定義
- [ ] 指定期間の日付をループ
- [ ] 該当する曜日のみOrderを生成
- [ ] 既存Orderと重複しないチェック
- [ ] トランザクション処理

#### RecurringOrderGenerator サービス作成
- [ ] `app/services/recurring_order_generator.rb` 作成
- [ ] generate_for_period メソッド実装
- [ ] エラーハンドリング

#### Rakeタスク作成
- [ ] `lib/tasks/orders.rake` 作成
- [ ] orders:generate タスク実装
- [ ] 引数で週数を指定可能に

#### バックグラウンドジョブ作成
- [ ] `app/jobs/generate_orders_job.rb` 作成
- [ ] perform メソッド実装

#### テスト作成
- [ ] generate_orders_for_range のテスト
- [ ] RecurringOrderGenerator のテスト
- [ ] 生成されたOrderの検証

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
- [ ] `app/dashboards/recurring_order_dashboard.rb` 作成
- [ ] ATTRIBUTE_TYPES 定義
- [ ] COLLECTION_ATTRIBUTES 定義
- [ ] SHOW_PAGE_ATTRIBUTES 定義
- [ ] FORM_ATTRIBUTES 定義

#### Controller作成
- [ ] `app/controllers/admin/recurring_orders_controller.rb` 作成
- [ ] routes.rb に追加

#### フォームカスタマイズ
- [ ] `app/views/admin/recurring_orders/_form.html.erb` 作成
- [ ] 曜日選択のUI改善
- [ ] 時刻入力のUI改善

#### 一括生成ボタン追加
- [ ] index画面に「Order自動生成」ボタン追加
- [ ] generate_orders アクション実装
- [ ] 成功メッセージ表示

#### ナビゲーション追加
- [ ] `app/views/admin/application/_navigation.html.erb` に追加

**確認項目:**
- [ ] /admin/recurring_orders にアクセスできる
- [ ] 新規作成できる
- [ ] 編集できる
- [ ] 削除できる
- [ ] 一括生成ボタンが動作する

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
- [ ] Gemfile に `gem 'prawn'` 追加
- [ ] Gemfile に `gem 'prawn-table'` 追加
- [ ] `bundle install` 実行

#### 日本語フォント準備
- [ ] `app/assets/fonts/` ディレクトリ作成
- [ ] NotoSansJP-Regular.otf ダウンロード
- [ ] フォント配置確認

#### DeliverySheetPdfGenerator サービス作成
- [ ] `app/services/delivery_sheet_pdf_generator.rb` 作成
- [ ] generate メソッド実装
- [ ] generate_daily_sheet メソッド実装
- [ ] テーブル形式で配送情報表示

#### OrdersController にアクション追加
- [ ] delivery_sheet_pdf アクション追加
- [ ] routes.rb に追加
- [ ] send_data でPDF返却

#### テスト
- [ ] PDF生成テスト
- [ ] 日本語表示確認

**確認項目:**
- [ ] PDFが生成される
- [ ] 日本語が正しく表示される
- [ ] レイアウトが見やすい
- [ ] ダウンロードできる
- [ ] 配送フロー関連の項目が表示される
  - [ ] 倉庫集荷時刻
  - [ ] 飲食店集荷時刻
  - [ ] 器材回収時刻
  - [ ] 返却先（倉庫/飲食店）
  - [ ] 器材メモ
  - [ ] 試食会/本導入の区別

---

### Day 17-18: 配送シートExcel生成（Caxlsx）

#### Gem インストール
- [ ] Gemfile に `gem 'caxlsx'` 追加
- [ ] Gemfile に `gem 'caxlsx_rails'` 追加
- [ ] `bundle install` 実行

#### DeliverySheetExcelGenerator サービス作成
- [ ] `app/services/delivery_sheet_excel_generator.rb` 作成
- [ ] generate メソッド実装
- [ ] generate_daily_sheet メソッド実装
- [ ] 日付ごとにシート分割

#### OrdersController にアクション追加
- [ ] delivery_sheet_excel アクション追加
- [ ] routes.rb に追加
- [ ] send_data でExcel返却

#### セルの書式設定
- [ ] ヘッダー行を太字
- [ ] 列幅の自動調整
- [ ] 罫線設定

#### テスト
- [ ] Excel生成テスト
- [ ] シート分割確認

**確認項目:**
- [ ] Excelファイルが生成される
- [ ] 日付ごとにシートが分かれている
- [ ] Excelで開いて編集できる
- [ ] 書式が適切
- [ ] 配送フロー関連の項目がすべて含まれている
  - [ ] 倉庫集荷時刻
  - [ ] 飲食店集荷時刻
  - [ ] 器材回収時刻
  - [ ] 返却先
  - [ ] 器材メモ
  - [ ] 試食会/本導入

---

### Day 19-20: 配送シート画面の実装

#### 配送シート一覧画面作成
- [ ] `app/views/admin/orders/delivery_sheets.html.erb` 作成
- [ ] 日付範囲フィルター
- [ ] 配送会社フィルター

#### プレビュー表示
- [ ] テーブル形式でプレビュー
- [ ] 並び順: 納品時間順

#### 一括出力機能
- [ ] 「PDF出力」ボタン
- [ ] 「Excel出力」ボタン
- [ ] 選択したOrderのみ出力

#### ナビゲーション追加
- [ ] サイドバーに「配送シート」リンク追加

**確認項目:**
- [ ] /admin/orders/delivery_sheets にアクセスできる
- [ ] フィルターが動作する
- [ ] プレビューが見やすい
- [ ] PDF/Excel両方出力できる

---

### Day 21: 日本語フォント設定

#### フォントファイル確認
- [ ] NotoSansJP-Regular.otf が配置されている
- [ ] パスが正しい

#### Prawn設定
- [ ] `config/initializers/prawn.rb` 作成
- [ ] hide_m17n_warning 設定

#### フォント適用
- [ ] DeliverySheetPdfGenerator でフォント指定
- [ ] すべての日本語テキストで確認

**確認項目:**
- [ ] PDFで日本語が正しく表示される
- [ ] 文字化けがない
- [ ] 警告が出ない

---

## Week 4: 制約チェック + テスト

### Day 22-23: バリデーション・制約チェック強化

#### 飲食店キャパチェック
- [ ] restaurant_capacity_check バリデーション実装
- [ ] 1日の合計食数をチェック
- [ ] エラーメッセージ表示

#### 定休日チェック
- [ ] restaurant_not_closed バリデーション実装
- [ ] 曜日ベースの定休日チェック
- [ ] エラーメッセージ表示

#### 配送時間制約チェック
- [ ] delivery_time_feasible バリデーション実装
- [ ] 集荷→納品の時間計算
- [ ] 移動時間＋設置時間を考慮

#### ConflictDetector サービス作成
- [ ] `app/services/conflict_detector.rb` 作成
- [ ] detect_for_date メソッド実装
- [ ] キャパオーバー検出
- [ ] ドライバー重複検出
- [ ] メニュー重複検出

#### テスト作成
- [ ] バリデーションテスト
- [ ] ConflictDetector のテスト

**確認項目:**
- [ ] キャパオーバーが防止される
- [ ] 定休日登録が防止される
- [ ] 配送時間の矛盾が検出される
- [ ] コンフリクト一覧が取得できる

---

### Day 24-25: 統合テスト・調整

#### E2Eテスト作成
- [ ] `spec/features/recurring_orders_spec.rb` 作成
- [ ] 定期スケジュール登録のシナリオ
- [ ] Order自動生成のシナリオ
- [ ] カレンダー表示のシナリオ
- [ ] 配送シート出力のシナリオ

#### パフォーマンステスト
- [ ] N+1クエリチェック（bullet gem）
- [ ] 大量データでのカレンダー表示
- [ ] PDF/Excel生成速度

#### バグ修正
- [ ] バグリスト作成
- [ ] 優先度付け
- [ ] 修正実施

#### ドキュメント更新
- [ ] README.md 更新
- [ ] 操作マニュアル作成
- [ ] データ移行手順書作成
- [ ] ロールバック手順書作成

**確認項目:**
- [ ] すべてのE2Eテストがパスする
- [ ] パフォーマンスに問題がない
- [ ] 致命的なバグがない
- [ ] ドキュメントが揃っている

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
