# Phase 2 タスクチェックリスト

**Phase 2: 請求・支払い管理 + 在庫管理システム**

このチェックリストに沿って開発を進めてください。各タスク完了時に `[ ]` を `[x]` に変更します。

---

## Phase 2 概要

### 目的
- 請求書の自動生成と管理の自動化
- 支払状況のリアルタイムトラッキング
- 器材・消耗品の在庫管理
- 在庫補充の自動アラート

### スコープ
- Week 1-2: 請求管理（Invoices, InvoiceItems）
- Week 3-4: 支払管理（Payments, 入金管理）
- Week 5-6: 在庫管理（Supplies, SupplyMovements）
- Week 7-8: テスト・統合・ドキュメント

---

## Week 1-2: 請求管理

### Day 1-2: データベース設計・マイグレーション

#### マイグレーションファイル作成
- [x] `rails g model Invoice` 実行
- [x] `rails g model InvoiceItem` 実行
- [ ] `rails g migration AddInvoiceFieldsToCompanies` 実行（不要: Companyモデルに直接関連付けを追加）

#### Invoiceテーブル設計
- [x] カラム定義
  - [x] company_id (bigint, null: false)
  - [x] invoice_number (string, null: false, unique)
  - [x] issue_date (date, null: false)
  - [x] payment_due_date (date, null: false)
  - [x] billing_period_start (date, null: false)
  - [x] billing_period_end (date, null: false)
  - [x] subtotal (integer, default: 0)
  - [x] tax_amount (integer, default: 0)
  - [x] total_amount (integer, null: false)
  - [x] status (string, null: false, default: 'draft')
  - [x] payment_status (string, default: 'unpaid')
  - [x] notes (text)
  - [x] timestamps
- [x] インデックス追加
  - [x] company_id
  - [x] invoice_number (unique)
  - [x] issue_date
  - [x] status
  - [x] payment_status
- [x] 外部キー制約追加

#### InvoiceItemテーブル設計
- [x] カラム定義
  - [x] invoice_id (bigint, null: false)
  - [x] order_id (bigint)
  - [x] description (string, null: false)
  - [x] quantity (integer, default: 1)
  - [x] unit_price (integer, null: false)
  - [x] amount (integer, null: false)
  - [x] timestamps
- [x] インデックス追加
  - [x] invoice_id
  - [x] order_id
- [x] 外部キー制約追加

#### マイグレーション実行
- [x] `rails db:migrate` 成功
- [x] `rails db:rollback` 成功（確認後、再度migrate）
- [x] `rails db:migrate:status` で確認

**確認コマンド:**
```bash
rails db:migrate
rails c
> Invoice
> Invoice.column_names
> InvoiceItem.column_names
```

---

### Day 3-4: Invoiceモデルの実装

#### Invoiceモデル作成
- [x] `app/models/invoice.rb` 作成
- [x] アソシエーション定義
  - [x] belongs_to :company
  - [x] has_many :invoice_items, dependent: :destroy
  - [x] has_many :orders, through: :invoice_items
  - [x] has_many :payments, dependent: :destroy
- [x] バリデーション追加
  - [x] invoice_number: presence, uniqueness
  - [x] issue_date: presence
  - [x] payment_due_date: presence
  - [x] total_amount: presence, numericality
  - [x] status: inclusion in %w[draft sent paid cancelled]
  - [x] payment_status: inclusion in %w[unpaid partial paid overdue]
- [x] スコープ定義
  - [x] scope :draft
  - [x] scope :sent
  - [x] scope :paid
  - [x] scope :unpaid
  - [x] scope :overdue
  - [x] scope :for_company
  - [x] scope :for_period

#### InvoiceItemモデル作成
- [x] `app/models/invoice_item.rb` 作成
- [x] アソシエーション定義
  - [x] belongs_to :invoice
  - [x] belongs_to :order, optional: true
- [x] バリデーション追加
  - [x] description: presence
  - [x] quantity: numericality (greater_than: 0)
  - [x] unit_price: numericality
  - [x] amount: numericality
- [x] コールバック追加
  - [x] before_validation :calculate_amount
  - [x] after_save :update_invoice_total
  - [x] after_destroy :update_invoice_total

#### ビジネスロジック実装
- [x] 請求書番号の自動生成
  - [x] generate_invoice_number メソッド
  - [x] フォーマット: INV-YYYYMM-XXXX
- [x] 金額計算
  - [x] calculate_subtotal
  - [x] calculate_tax
  - [x] calculate_total
- [x] ステータス管理
  - [x] mark_as_sent
  - [x] mark_as_paid
  - [x] cancel
- [x] 支払期限チェック
  - [x] overdue?
  - [x] days_until_due
  - [x] days_overdue

**確認コマンド:**
```bash
rails c
> Invoice.create!(company: Company.first, ...)
> invoice.invoice_items.create!(...)
```

---

### Day 5-6: 請求書自動生成機能

#### InvoiceGeneratorサービス作成
- [x] `app/services/invoice_generator.rb` 作成
- [x] generate_monthly_invoice メソッド実装
  - [x] 指定期間の案件を取得
  - [x] 案件ごとに明細行を作成
  - [x] 金額を集計
  - [x] 請求書を生成
- [x] エラーハンドリング

#### 請求明細の集計ロジック
- [x] 企業ごとの月次集計
- [x] 食数×単価の計算
- [x] 割引の適用（固定額・パーセント）
- [x] 消費税の計算

#### Rakeタスク作成
- [x] `lib/tasks/invoices.rake` 作成
- [x] invoices:generate_monthly タスク実装
  - [x] 対象企業の指定
  - [x] 請求期間の指定
  - [x] 一括生成機能

#### バックグラウンドジョブ作成
- [x] `app/jobs/generate_invoices_job.rb` 作成
- [x] perform メソッド実装
- [ ] スケジュール設定（月末自動実行）

**確認コマンド:**
```bash
rails invoices:generate_monthly[2025,12]
rails c
> GenerateInvoicesJob.perform_now(2025, 12)
```

---

### Day 7-8: 請求書PDF出力

#### InvoicePdfGeneratorサービス作成
- [ ] `app/services/invoice_pdf_generator.rb` 作成
- [ ] A4縦向きレイアウト
- [ ] 請求書ヘッダー
  - [ ] 請求書番号
  - [ ] 発行日
  - [ ] 支払期限
- [ ] 請求先情報
  - [ ] 企業名
  - [ ] 住所
  - [ ] 担当者
- [ ] 請求明細テーブル
  - [ ] 案件日付
  - [ ] 内容（飲食店名・メニュー名）
  - [ ] 数量
  - [ ] 単価
  - [ ] 金額
- [ ] 合計金額
  - [ ] 小計
  - [ ] 消費税
  - [ ] 合計
- [ ] 振込先情報
- [ ] 備考欄

#### コントローラーにアクション追加
- [ ] InvoicesController#show_pdf
- [ ] routes.rb に追加

**確認項目:**
- [ ] PDFが生成される
- [ ] 日本語が正しく表示される
- [ ] レイアウトが整っている
- [ ] 印刷に適している

---

### Day 9-10: 管理画面実装（Invoices）

#### Dashboard作成
- [ ] `app/dashboards/invoice_dashboard.rb` 作成
- [ ] ATTRIBUTE_TYPES 定義
- [ ] COLLECTION_ATTRIBUTES 定義
- [ ] SHOW_PAGE_ATTRIBUTES 定義
- [ ] FORM_ATTRIBUTES 定義

#### Controller作成
- [ ] `app/controllers/admin/invoices_controller.rb` 作成
- [ ] index: 請求書一覧
- [ ] show: 請求書詳細
- [ ] new/create: 手動作成
- [ ] edit/update: 編集
- [ ] destroy: 削除
- [ ] カスタムアクション
  - [ ] generate_for_company: 企業別生成
  - [ ] send_invoice: 送信
  - [ ] mark_as_paid: 支払済みマーク

#### ビュー作成
- [ ] 請求書一覧画面
  - [ ] フィルター（企業、ステータス、期間）
  - [ ] ソート機能
  - [ ] PDF出力ボタン
- [ ] 請求書詳細画面
  - [ ] 明細一覧
  - [ ] ステータス変更ボタン
  - [ ] PDF出力ボタン

**確認項目:**
- [ ] /admin/invoices にアクセスできる
- [ ] 請求書を作成できる
- [ ] ステータスを変更できる
- [ ] PDF出力できる

---

## Week 3-4: 支払管理

### Day 11-12: Paymentモデル実装

#### マイグレーション作成
- [ ] `rails g model Payment` 実行
- [ ] カラム定義
  - [ ] invoice_id (bigint, null: false)
  - [ ] payment_date (date, null: false)
  - [ ] amount (integer, null: false)
  - [ ] payment_method (string)
  - [ ] reference_number (string)
  - [ ] notes (text)
  - [ ] timestamps
- [ ] インデックス追加
- [ ] 外部キー制約追加
- [ ] `rails db:migrate` 実行

#### Paymentモデル作成
- [ ] `app/models/payment.rb` 作成
- [ ] アソシエーション定義
  - [ ] belongs_to :invoice
- [ ] バリデーション追加
  - [ ] payment_date: presence
  - [ ] amount: presence, numericality
  - [ ] amount <= invoice remaining balance
- [ ] コールバック追加
  - [ ] after_create :update_invoice_payment_status
  - [ ] after_destroy :update_invoice_payment_status

#### ビジネスロジック実装
- [ ] 支払記録の登録
- [ ] 請求書の支払状況更新
  - [ ] 全額支払い → paid
  - [ ] 一部支払い → partial
  - [ ] 未払い → unpaid
  - [ ] 期限超過 → overdue

**確認コマンド:**
```bash
rails c
> invoice = Invoice.first
> invoice.payments.create!(payment_date: Date.today, amount: 10000)
> invoice.reload.payment_status
```

---

### Day 13-14: 入金管理画面

#### Dashboard作成
- [ ] `app/dashboards/payment_dashboard.rb` 作成
- [ ] ATTRIBUTE_TYPES 定義

#### Controller作成
- [ ] `app/controllers/admin/payments_controller.rb` 作成
- [ ] index: 入金一覧
- [ ] new/create: 入金登録
- [ ] edit/update: 編集
- [ ] destroy: 削除

#### ビュー作成
- [ ] 入金一覧画面
  - [ ] 請求書別の入金状況
  - [ ] フィルター機能
  - [ ] 入金合計の表示
- [ ] 入金登録フォーム
  - [ ] 請求書選択
  - [ ] 入金日
  - [ ] 入金額
  - [ ] 支払方法
  - [ ] 参照番号

**確認項目:**
- [ ] /admin/payments にアクセスできる
- [ ] 入金を登録できる
- [ ] 請求書の支払状況が自動更新される

---

### Day 15-16: 未払いアラート機能

#### UnpaidInvoiceCheckerサービス作成
- [ ] `app/services/unpaid_invoice_checker.rb` 作成
- [ ] 期限超過の請求書を検出
- [ ] アラートメール送信

#### メーラー作成
- [ ] `app/mailers/invoice_mailer.rb` 作成
- [ ] overdue_notice メソッド
- [ ] payment_reminder メソッド
- [ ] メールテンプレート作成

#### Rakeタスク作成
- [ ] `lib/tasks/invoices.rake` に追加
- [ ] invoices:check_overdue タスク実装
- [ ] 毎日自動実行の設定（Sidekiq Scheduler）

#### ダッシュボード作成
- [ ] 未払い請求書一覧
- [ ] 期限超過の警告表示
- [ ] 合計未払額の表示

**確認項目:**
- [ ] 期限超過の請求書が検出される
- [ ] アラートメールが送信される
- [ ] ダッシュボードに表示される

---

### Day 17-18: 支払状況レポート

#### ReportGeneratorサービス作成
- [ ] `app/services/payment_report_generator.rb` 作成
- [ ] 月次レポート生成
- [ ] 企業別集計
- [ ] 支払状況サマリー

#### レポート画面作成
- [ ] 月次レポート画面
  - [ ] 請求額合計
  - [ ] 入金額合計
  - [ ] 未払額合計
  - [ ] 企業別内訳
- [ ] グラフ表示（Chart.js）
  - [ ] 月別推移
  - [ ] 企業別比率

#### PDF/CSV出力
- [ ] レポートのPDF出力
- [ ] レポートのCSV出力

**確認項目:**
- [ ] レポートが表示される
- [ ] グラフが正しく表示される
- [ ] PDF/CSV出力できる

---

## Week 5-6: 在庫管理

### Day 19-20: Supplyモデル実装

#### マイグレーション作成
- [ ] `rails g model Supply` 実行
- [ ] カラム定義
  - [ ] name (string, null: false)
  - [ ] category (string)
  - [ ] unit (string, default: '個')
  - [ ] current_stock (integer, default: 0)
  - [ ] minimum_stock (integer, default: 0)
  - [ ] unit_price (integer)
  - [ ] notes (text)
  - [ ] timestamps
- [ ] インデックス追加
- [ ] `rails db:migrate` 実行

#### Supplyモデル作成
- [ ] `app/models/supply.rb` 作成
- [ ] アソシエーション定義
  - [ ] has_many :supply_movements
  - [ ] has_many :supply_stocks
- [ ] バリデーション追加
  - [ ] name: presence, uniqueness
  - [ ] current_stock: numericality
  - [ ] minimum_stock: numericality
- [ ] スコープ定義
  - [ ] scope :low_stock (在庫不足)
  - [ ] scope :out_of_stock (在庫切れ)
  - [ ] scope :by_category

#### ビジネスロジック実装
- [ ] 在庫不足判定
  - [ ] low_stock?
  - [ ] out_of_stock?
- [ ] 在庫補充推奨数
  - [ ] recommended_reorder_quantity

**確認コマンド:**
```bash
rails c
> Supply.create!(name: '弁当箱', current_stock: 100, minimum_stock: 50)
> Supply.low_stock
```

---

### Day 21-22: 入出庫管理

#### SupplyMovementモデル作成
- [ ] `rails g model SupplyMovement` 実行
- [ ] カラム定義
  - [ ] supply_id (bigint, null: false)
  - [ ] movement_type (string, null: false)
  - [ ] quantity (integer, null: false)
  - [ ] movement_date (date, null: false)
  - [ ] from_location (string)
  - [ ] to_location (string)
  - [ ] order_id (bigint)
  - [ ] notes (text)
  - [ ] timestamps
- [ ] インデックス追加
- [ ] 外部キー制約追加
- [ ] `rails db:migrate` 実行

#### SupplyMovementモデル作成
- [ ] `app/models/supply_movement.rb` 作成
- [ ] アソシエーション定義
  - [ ] belongs_to :supply
  - [ ] belongs_to :order, optional: true
- [ ] バリデーション追加
  - [ ] movement_type: inclusion in %w[入庫 出庫 移動 調整]
  - [ ] quantity: numericality
  - [ ] movement_date: presence
- [ ] コールバック追加
  - [ ] after_create :update_supply_stock
  - [ ] before_destroy :prevent_deletion_if_locked

#### 在庫更新ロジック
- [ ] 入庫 → current_stock 増加
- [ ] 出庫 → current_stock 減少
- [ ] 移動 → location間の移動記録
- [ ] 調整 → 棚卸し調整

**確認コマンド:**
```bash
rails c
> supply = Supply.first
> supply.supply_movements.create!(movement_type: '入庫', quantity: 50, movement_date: Date.today)
> supply.reload.current_stock
```

---

### Day 23-24: 在庫管理画面

#### Dashboard作成
- [ ] `app/dashboards/supply_dashboard.rb` 作成
- [ ] `app/dashboards/supply_movement_dashboard.rb` 作成

#### Controller作成
- [ ] `app/controllers/admin/supplies_controller.rb` 作成
- [ ] `app/controllers/admin/supply_movements_controller.rb` 作成

#### ビュー作成
- [ ] 在庫一覧画面
  - [ ] 在庫不足の警告表示
  - [ ] カテゴリ別表示
  - [ ] 在庫推移グラフ
- [ ] 入出庫記録画面
  - [ ] 入庫登録フォーム
  - [ ] 出庫登録フォーム
  - [ ] 移動記録
  - [ ] 履歴表示

**確認項目:**
- [ ] /admin/supplies にアクセスできる
- [ ] 在庫を登録できる
- [ ] 入出庫を記録できる
- [ ] 在庫不足が表示される

---

### Day 25-26: 在庫補充アラート

#### LowStockCheckerサービス作成
- [ ] `app/services/low_stock_checker.rb` 作成
- [ ] 在庫不足を検出
- [ ] アラートメール送信

#### メーラー作成
- [ ] `app/mailers/supply_mailer.rb` 作成
- [ ] low_stock_alert メソッド
- [ ] out_of_stock_alert メソッド

#### Rakeタスク作成
- [ ] `lib/tasks/supplies.rake` 作成
- [ ] supplies:check_stock タスク実装
- [ ] 毎日自動実行の設定

#### ダッシュボード作成
- [ ] 在庫不足一覧
- [ ] 補充推奨リスト
- [ ] 在庫アラート表示

**確認項目:**
- [ ] 在庫不足が検出される
- [ ] アラートメールが送信される
- [ ] ダッシュボードに表示される

---

## Week 7-8: テスト・統合・ドキュメント

### Day 27-28: RSpecテスト作成

#### モデルテスト
- [ ] `spec/models/invoice_spec.rb` 作成
- [ ] `spec/models/invoice_item_spec.rb` 作成
- [ ] `spec/models/payment_spec.rb` 作成
- [ ] `spec/models/supply_spec.rb` 作成
- [ ] `spec/models/supply_movement_spec.rb` 作成

#### サービステスト
- [ ] `spec/services/invoice_generator_spec.rb` 作成
- [ ] `spec/services/invoice_pdf_generator_spec.rb` 作成
- [ ] `spec/services/unpaid_invoice_checker_spec.rb` 作成
- [ ] `spec/services/low_stock_checker_spec.rb` 作成

#### E2Eテスト
- [ ] `spec/features/invoices_spec.rb` 作成
- [ ] `spec/features/payments_spec.rb` 作成
- [ ] `spec/features/supplies_spec.rb` 作成

**確認項目:**
- [ ] すべてのテストがパスする
- [ ] カバレッジが80%以上

---

### Day 29-30: パフォーマンステスト・最適化

#### N+1クエリチェック
- [ ] Bullet で警告がないか確認
- [ ] includes/preload の最適化

#### パフォーマンステスト
- [ ] 大量データでのテスト（100件以上の請求書）
- [ ] PDF生成速度テスト
- [ ] レポート生成速度テスト

#### 最適化
- [ ] データベースインデックスの最適化
- [ ] クエリの最適化
- [ ] キャッシュの導入

**確認項目:**
- [ ] ページ読み込みが1秒以内
- [ ] PDF生成が3秒以内
- [ ] N+1クエリがない

---

### Day 31-32: ドキュメント作成

#### 操作マニュアル更新
- [ ] 請求書管理の操作方法
- [ ] 入金管理の操作方法
- [ ] 在庫管理の操作方法

#### API仕様書作成（将来のAPI化に備えて）
- [ ] エンドポイント一覧
- [ ] リクエスト/レスポンス例

#### データ移行手順書
- [ ] 既存請求書データの移行
- [ ] 在庫データの初期投入

**確認項目:**
- [ ] 操作マニュアルが揃っている
- [ ] データ移行手順が明確

---

### Day 33-35: 実運用テスト

#### 本番環境デプロイ
- [ ] Phase 2機能のデプロイ
- [ ] マイグレーション実行
- [ ] 動作確認

#### データ移行
- [ ] 既存請求書データの移行
- [ ] 在庫データの初期投入
- [ ] データ検証

#### 1週間の実運用テスト
- [ ] Day 1: 請求書生成テスト
- [ ] Day 2: 入金登録テスト
- [ ] Day 3: 在庫管理テスト
- [ ] Day 4: アラート機能テスト
- [ ] Day 5: レポート出力テスト
- [ ] Day 6: トラブル対応
- [ ] Day 7: 総合確認

**確認項目:**
- [ ] 実運用で1週間問題なく回せた
- [ ] 致命的なバグがない
- [ ] スタッフが自力で操作できる

---

## Phase 2 完了判定

以下すべてにチェックが入ったらPhase 2完了です。

### 機能
- [ ] 請求書を自動生成できる
- [ ] 請求書をPDF出力できる
- [ ] 入金を管理できる
- [ ] 未払いアラートが機能する
- [ ] 在庫を管理できる
- [ ] 在庫補充アラートが機能する

### 品質
- [ ] すべてのテストがパスする
- [ ] パフォーマンスに問題がない
- [ ] 致命的なバグがない

### 運用
- [ ] 実運用テストで問題なし
- [ ] スタッフが自力で操作できる
- [ ] 操作マニュアルがある

---

## 次のステップ

Phase 2完了後、Phase 3（配送会社向け機能＋モバイル対応）に進みます。
