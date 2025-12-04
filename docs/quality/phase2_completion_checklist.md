# Phase 2 完了チェックリスト

**Phase 2: 請求・支払い管理、在庫管理システム**

最終更新: 2025-12-04

---

## 目次

1. [実装チェックリスト](#実装チェックリスト)
2. [テストチェックリスト](#テストチェックリスト)
3. [ドキュメントチェックリスト](#ドキュメントチェックリスト)
4. [品質チェックリスト](#品質チェックリスト)
5. [デプロイ準備チェックリスト](#デプロイ準備チェックリスト)
6. [本番環境デプロイチェックリスト](#本番環境デプロイチェックリスト)

---

## 実装チェックリスト

### Week 1-2: 請求書機能

#### モデル
- [x] Invoice モデル作成
  - [x] アソシエーション（Company, InvoiceItem, Payment）
  - [x] バリデーション（必須項目、金額）
  - [x] 請求書番号自動生成（INV-YYYYMM-XXXX）
  - [x] 金額計算ロジック（小計・消費税・合計）
  - [x] ステータス管理（draft/sent/paid/cancelled）
  - [x] 支払ステータス管理（unpaid/partial/paid/overdue）

- [x] InvoiceItem モデル作成
  - [x] アソシエーション（Invoice）
  - [x] バリデーション（必須項目、金額）
  - [x] 金額計算ロジック
  - [x] コールバック（請求書金額への反映）

#### サービス
- [x] InvoiceGenerator 作成
  - [x] 月次請求書自動生成
  - [x] 企業別・月別集計
  - [x] 消費税計算（10%）
  - [x] 重複チェック

- [x] InvoicePdfGenerator 作成
  - [x] Prawn使用
  - [x] A4縦向き
  - [x] 日本語フォント対応（Noto Sans JP）
  - [x] 企業情報表示
  - [x] 請求明細表示
  - [x] 金額計算表示

#### コントローラー・Dashboard
- [x] InvoiceDashboard 作成
- [x] Admin::InvoicesController 作成
- [x] Admin::InvoiceItemsController 作成
- [x] Admin::InvoiceGenerationsController 作成
- [x] Admin::InvoicePdfsController 作成

#### Rakeタスク
- [x] invoices:generate_monthly タスク作成

#### マイグレーション
- [x] create_invoices マイグレーション
- [x] create_invoice_items マイグレーション

---

### Week 3-4: 入金・レポート機能

#### モデル
- [x] Payment モデル作成
  - [x] アソシエーション（Invoice）
  - [x] バリデーション（必須項目、金額、残高チェック）
  - [x] コールバック（請求書ステータス更新）

#### サービス
- [x] UnpaidInvoiceChecker 作成
  - [x] 期限超過請求書の検出
  - [x] 支払リマインダー機能
  - [x] ステータス自動更新

- [x] ReportGeneratorService 作成
  - [x] 月次支払状況レポート生成
  - [x] 支払ステータス別集計
  - [x] 企業別集計
  - [x] 期限超過請求書リスト
  - [x] 最近の入金リスト

- [x] ReportPdfGenerator 作成
  - [x] PDFレポート生成
  - [x] Prawn使用
  - [x] 日本語フォント対応

#### コントローラー・Dashboard
- [x] PaymentDashboard 作成
- [x] Admin::PaymentsController 作成
- [x] Admin::ReportsController 作成
  - [x] レポート表示画面
  - [x] Chart.js用グラフデータ生成
  - [x] PDF/CSVエクスポート機能

#### Mailer
- [x] InvoiceMailer 作成
  - [x] overdue_notice（期限超過通知）
  - [x] payment_reminder（支払リマインダー）
  - [x] HTML/テキスト両形式

#### Rakeタスク
- [x] invoices:check_overdue タスク作成

#### マイグレーション
- [x] create_payments マイグレーション

---

### Week 5-6: 在庫管理機能

#### モデル
- [x] Supply モデル作成
  - [x] アソシエーション（SupplyStock, SupplyMovement）
  - [x] バリデーション（必須項目、SKU一意性）
  - [x] 在庫計算メソッド（total_stock）
  - [x] 在庫ステータス判定（low_stock?, out_of_stock?）

- [x] SupplyStock モデル作成
  - [x] アソシエーション（Supply, Location polymorphic）
  - [x] バリデーション（必須項目、数量）
  - [x] 棚卸し機能（physical_count）

- [x] SupplyMovement モデル作成
  - [x] アソシエーション（Supply）
  - [x] バリデーション（必須項目、移動タイプ）
  - [x] コールバック（在庫数更新）
  - [x] 入荷・消費・移動の処理

#### サービス
- [x] LowStockChecker 作成
  - [x] 在庫不足検出（reorder_point以下）
  - [x] 在庫切れ検出（quantity = 0）
  - [x] アラートメール送信

#### コントローラー・Dashboard
- [x] SupplyDashboard 作成
- [x] SupplyStockDashboard 作成
- [x] SupplyMovementDashboard 作成
- [x] Admin::SuppliesController 作成
- [x] Admin::SupplyStocksController 作成
- [x] Admin::SupplyMovementsController 作成
- [x] Admin::BulkSupplyMovementsController 作成

#### Mailer
- [x] SupplyMailer 作成
  - [x] low_stock_alert（在庫不足通知）
  - [x] out_of_stock_alert（在庫切れ通知）
  - [x] HTML/テキスト両形式

#### Rakeタスク
- [x] supplies:check_stock タスク作成
- [x] supplies:list タスク作成
- [x] supplies:low_stock タスク作成

#### マイグレーション
- [x] create_supplies マイグレーション
- [x] create_supply_stocks マイグレーション
- [x] create_supply_movements マイグレーション

---

### Week 7-8: テスト・パフォーマンス・ドキュメント

#### テスト（RSpec）

**モデルテスト（請求書関連）**:
- [x] spec/models/invoice_spec.rb
- [x] spec/models/invoice_item_spec.rb
- [x] spec/models/payment_spec.rb

**モデルテスト（在庫関連）**:
- [ ] spec/models/supply_spec.rb ⚠️ 未実装
- [ ] spec/models/supply_stock_spec.rb ⚠️ 未実装
- [ ] spec/models/supply_movement_spec.rb ⚠️ 未実装

**サービステスト**:
- [x] spec/services/invoice_generator_spec.rb
- [x] spec/services/unpaid_invoice_checker_spec.rb
- [x] spec/services/low_stock_checker_spec.rb
- [ ] spec/services/report_generator_service_spec.rb ⚠️ 未実装

**リクエストテスト**:
- [x] spec/requests/admin/invoices_spec.rb
- [ ] spec/requests/admin/invoice_generations_spec.rb ⚠️ 未実装
- [ ] spec/requests/admin/invoice_pdfs_spec.rb ⚠️ 未実装

**Factory**:
- [x] spec/factories/invoices.rb
- [x] spec/factories/invoice_items.rb
- [x] spec/factories/payments.rb
- [ ] spec/factories/supplies.rb ⚠️ 未実装
- [ ] spec/factories/supply_stocks.rb ⚠️ 未実装
- [ ] spec/factories/supply_movements.rb ⚠️ 未実装

#### パフォーマンス最適化
- [x] N+1クエリ対策
  - [x] InvoiceDashboard に collection_includes 追加
  - [x] PaymentDashboard に collection_includes 追加
  - [x] SupplyDashboard に collection_includes 追加

- [x] データベースインデックス追加
  - [x] invoices.billing_period_start
  - [x] invoices.payment_due_date
  - [x] 複合インデックス (billing_period_start, payment_status)

- [x] パフォーマンステストツール作成
  - [x] performance:generate_test_data タスク
  - [x] performance:benchmark タスク
  - [x] performance:clean_test_data タスク

- [x] ベンチマーク実行・検証
  - [x] レポート生成 < 1.0秒 ✅
  - [x] 請求書一覧（100件）< 0.5秒 ✅
  - [x] 期限超過チェック < 0.5秒 ✅
  - [x] 在庫不足チェック < 0.5秒 ✅

#### ドキュメント
- [x] 請求書管理操作マニュアル (docs/manuals/invoice_management.md)
- [x] 入金管理操作マニュアル (docs/manuals/payment_management.md)
- [x] 在庫管理操作マニュアル (docs/manuals/inventory_management.md)
- [x] データ移行手順書 (docs/migration/phase2_data_migration.md)
- [x] システム構成ドキュメント (docs/architecture/phase2_system_architecture.md)
- [x] README.md更新

---

## テストチェックリスト

### テスト環境準備
- [ ] テスト環境のマイグレーション実行 ⚠️ 未実行
  ```bash
  RAILS_ENV=test bin/rails db:migrate
  ```

### テストカバレッジ

**現在のカバレッジ**:
- 請求書関連: ✅ 80% 程度
- 入金関連: ✅ 80% 程度
- 在庫関連: ❌ 20% 程度（テスト不足）

**目標カバレッジ**: 80% 以上

### テスト実行

- [ ] 全テストが成功すること
  ```bash
  bundle exec rspec
  ```

- [ ] 各機能のテストが成功すること
  ```bash
  # 請求書関連
  bundle exec rspec spec/models/invoice_spec.rb
  bundle exec rspec spec/services/invoice_generator_spec.rb

  # 入金関連
  bundle exec rspec spec/models/payment_spec.rb
  bundle exec rspec spec/services/unpaid_invoice_checker_spec.rb

  # 在庫関連（実装後）
  # bundle exec rspec spec/models/supply_spec.rb
  # bundle exec rspec spec/services/low_stock_checker_spec.rb
  ```

---

## ドキュメントチェックリスト

### 操作マニュアル

- [x] 請求書管理操作マニュアル
  - [x] 請求書の一括生成手順
  - [x] 請求書の確認・編集方法
  - [x] PDF出力手順
  - [x] ステータス管理
  - [x] トラブルシューティング

- [x] 入金管理操作マニュアル
  - [x] 入金の登録方法
  - [x] 入金履歴の確認
  - [x] 支払状況レポートの見方
  - [x] 期限超過アラートの仕組み
  - [x] トラブルシューティング

- [x] 在庫管理操作マニュアル
  - [x] 備品マスタの管理
  - [x] 在庫の確認・更新方法
  - [x] 在庫移動の記録
  - [x] 在庫補充アラートの仕組み
  - [x] 棚卸し作業手順
  - [x] トラブルシューティング

### 技術ドキュメント

- [x] データ移行手順書
  - [x] 移行前の準備
  - [x] 請求書データの移行
  - [x] 入金データの移行
  - [x] 在庫データの初期設定
  - [x] データ検証
  - [x] ロールバック手順
  - [x] トラブルシューティング

- [x] システム構成ドキュメント
  - [x] システム概要・技術スタック
  - [x] アーキテクチャ構成
  - [x] データベース設計（ER図、テーブル定義）
  - [x] 主要コンポーネント
  - [x] バッチ処理
  - [x] パフォーマンス最適化
  - [x] セキュリティ
  - [x] デプロイメント

- [x] 品質チェックレポート
  - [x] 調査結果サマリー
  - [x] 問題点の詳細
  - [x] 推奨される修正内容

### ドキュメントの整合性

- [ ] ドキュメントと実装の命名一致 ⚠️ 一部不一致
  - [ ] `InvoiceGeneratorService` → `InvoiceGenerator` に修正

- [x] ドキュメント間の相互リンク
- [x] 更新履歴の記載

---

## 品質チェックリスト

### コード品質

- [x] モデルのバリデーション実装
- [x] モデルのアソシエーション実装
- [x] コールバックの適切な使用
- [x] サービスクラスへのビジネスロジック分離
- [x] N+1クエリ対策（collection_includes）
- [x] データベースインデックス設定

### セキュリティ

- [x] 認証・認可（AdminUser, Devise）
- [x] 基本認証（本番環境）
- [x] SQLインジェクション対策（プレースホルダー使用）
- [x] XSS対策（ERBエスケープ）
- [x] 環境変数で機密情報管理

### パフォーマンス

- [x] レポート生成 < 1.0秒
- [x] 請求書一覧（100件）< 0.5秒
- [x] 期限超過チェック < 0.5秒
- [x] 在庫不足チェック < 0.5秒

### 不要ファイル削除

- [ ] ActiveAdmin関連ファイル削除 ⚠️ 未削除
  - [ ] `db/migrate/20251201033438_create_active_admin_comments.rb`
  - [ ] `config/locales/activeadmin.ja.yml`
  - [ ] `active_admin_comments` テーブル

---

## デプロイ準備チェックリスト

### コードの整理

- [ ] テスト環境マイグレーション実行完了
- [ ] 不足しているテスト実装完了
- [ ] 不要ファイル削除完了
- [ ] ドキュメント修正完了

### Git管理

- [ ] 全ファイルをGitに追加
  ```bash
  git add docs/ lib/tasks/ spec/ db/migrate/ app/
  ```

- [ ] コミット
  ```bash
  git commit -m "Phase 2完了: 請求・入金・在庫管理システム実装"
  ```

- [ ] リモートリポジトリにプッシュ
  ```bash
  git push origin main
  ```

### 環境変数確認

- [ ] 本番環境の環境変数設定確認
  ```bash
  # Heroku環境変数確認
  heroku config --app your-app-name

  # 必要な環境変数
  # - DATABASE_URL
  # - REDIS_URL
  # - AWS_ACCESS_KEY_ID
  # - AWS_SECRET_ACCESS_KEY
  # - AWS_REGION
  # - AWS_BUCKET
  # - ADMIN_USER（Basic認証用）
  # - ADMIN_PASSWORD（Basic認証用）
  ```

### データベースバックアップ

- [ ] 本番データベースのバックアップ取得
  ```bash
  heroku pg:backups:capture --app your-app-name
  heroku pg:backups:download --app your-app-name
  ```

### デプロイ手順確認

- [ ] デプロイコマンドの確認
  ```bash
  # Herokuデプロイ
  git push heroku main

  # マイグレーション実行
  heroku run rails db:migrate --app your-app-name

  # 動作確認
  heroku logs --tail --app your-app-name
  ```

---

## 本番環境デプロイチェックリスト

### デプロイ前

- [ ] チーム内でデプロイ日時を共有
- [ ] メンテナンス通知（必要に応じて）
- [ ] データベースバックアップ取得
- [ ] 環境変数設定確認

### デプロイ

- [ ] コードを本番環境にデプロイ
  ```bash
  git push heroku main
  ```

- [ ] マイグレーション実行
  ```bash
  heroku run rails db:migrate --app your-app-name
  ```

- [ ] アセットプリコンパイル（必要に応じて）
  ```bash
  heroku run rails assets:precompile --app your-app-name
  ```

### デプロイ後の確認

#### 基本動作確認
- [ ] 管理画面にログインできる
- [ ] 各ページが正常に表示される
- [ ] エラーログに異常なエラーがない

#### 請求書機能
- [ ] 請求書一覧が表示される
- [ ] 請求書の新規作成ができる
- [ ] 請求書の一括生成ができる
- [ ] 請求書PDFが出力できる
- [ ] 請求書のステータス変更ができる

#### 入金機能
- [ ] 入金一覧が表示される
- [ ] 入金の新規登録ができる
- [ ] 入金登録後、請求書のステータスが自動更新される
- [ ] 残高超過のバリデーションが機能する

#### レポート機能
- [ ] 月次支払状況レポートが表示される
- [ ] グラフが正常に表示される（Chart.js）
- [ ] PDFエクスポートができる
- [ ] CSVエクスポートができる

#### 在庫管理機能
- [ ] 備品一覧が表示される
- [ ] 備品の新規登録ができる
- [ ] 在庫の確認・更新ができる
- [ ] 在庫移動の記録ができる
- [ ] 在庫移動後、在庫数が自動更新される

#### バッチ処理
- [ ] 期限超過チェックが実行できる
  ```bash
  heroku run rails invoices:check_overdue --app your-app-name
  ```

- [ ] 在庫不足チェックが実行できる
  ```bash
  heroku run rails supplies:check_stock --app your-app-name
  ```

#### パフォーマンス確認
- [ ] ページ表示速度が許容範囲内（< 3秒）
- [ ] レポート生成速度が許容範囲内（< 2秒）
- [ ] PDF生成速度が許容範囲内（< 5秒）

### データ移行（既存データがある場合）

- [ ] CSVデータ準備
- [ ] データ移行スクリプト実行
- [ ] 移行データ検証
- [ ] 移行後の動作確認

### 運用開始

- [ ] ユーザーへの操作マニュアル共有
- [ ] 運用開始の通知
- [ ] 初期サポート体制の確立

---

## トラブルシューティング

### デプロイ時のエラー

#### マイグレーションエラー
```bash
# エラーログ確認
heroku logs --tail --app your-app-name

# ロールバック
heroku rollback --app your-app-name
heroku run rails db:rollback --app your-app-name
```

#### アセットエラー
```bash
# アセットプリコンパイル再実行
heroku run rails assets:clobber --app your-app-name
heroku run rails assets:precompile --app your-app-name
```

### 本番環境での問題

#### ログ確認
```bash
# リアルタイムログ
heroku logs --tail --app your-app-name

# エラーログのみ
heroku logs --tail --source app --app your-app-name | grep ERROR
```

#### データベース接続エラー
```bash
# データベース接続確認
heroku pg:info --app your-app-name

# データベース再起動
heroku pg:restart --app your-app-name
```

#### パフォーマンス問題
```bash
# Dyno再起動
heroku restart --app your-app-name

# パフォーマンスメトリクス確認
heroku pg:diagnose --app your-app-name
```

---

## Phase 2 完了基準

以下の全項目が完了した時点でPhase 2完了とする：

### 必須項目（Must Have）

- [x] 全モデル実装完了（Invoice, InvoiceItem, Payment, Supply, SupplyStock, SupplyMovement）
- [x] 全コントローラー実装完了
- [x] 全サービスクラス実装完了
- [x] 全Dashboard実装完了
- [x] 全マイグレーション実装完了
- [x] パフォーマンス最適化完了（N+1対策、インデックス）
- [x] 基本的なテスト実装（請求書・入金関連）
- [x] 操作マニュアル作成完了
- [x] 技術ドキュメント作成完了

### 推奨項目（Should Have）

- [ ] 全テスト実装完了（在庫関連含む）⚠️
- [ ] テスト環境マイグレーション実行 ⚠️
- [ ] 不要ファイル削除 ⚠️
- [ ] ドキュメント修正（命名統一）⚠️
- [ ] Git コミット完了

### 任意項目（Nice to Have）

- [ ] Sidekiq Schedulerの設定
- [ ] エラー通知の設定（Sentry等）
- [ ] モニタリングツールの設定（New Relic等）

---

**現在の完了率**: 約85%（必須項目完了、推奨項目一部未完了）

**次のアクション**: 推奨項目を完了してから本番デプロイに進むことを推奨

---

**更新履歴**:
- 2025-12-04: 初版作成
