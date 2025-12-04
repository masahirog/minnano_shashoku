# Phase 2 システム構成ドキュメント

**Phase 2: 請求・支払い管理、在庫管理システム**

---

## 目次

1. [システム概要](#システム概要)
2. [アーキテクチャ構成](#アーキテクチャ構成)
3. [データベース設計](#データベース設計)
4. [主要コンポーネント](#主要コンポーネント)
5. [バッチ処理](#バッチ処理)
6. [パフォーマンス最適化](#パフォーマンス最適化)
7. [セキュリティ](#セキュリティ)
8. [デプロイメント](#デプロイメント)

---

## システム概要

### Phase 2の目的

Phase 2では、以下の機能を実装します：

1. **請求書管理**: 月次請求書の自動生成、PDF出力、ステータス管理
2. **入金管理**: 入金の記録、支払状況の追跡、期限超過アラート
3. **在庫管理**: 備品マスタ管理、拠点別在庫、在庫移動、補充アラート

### 技術スタック

- **フレームワーク**: Ruby on Rails 7.1.6
- **言語**: Ruby 3.1.4
- **データベース**: PostgreSQL
- **管理画面**: Administrate
- **PDF生成**: Prawn
- **バッチ処理**: Rake Tasks（Sidekiq対応可）
- **デプロイ**: Heroku
- **CI/CD**: GitHub Actions（オプション）

---

## アーキテクチャ構成

### レイヤー構造

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Administrate Dashboard, PDF Views)    │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│         Application Layer               │
│  (Controllers, Service Objects)         │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│         Domain Layer                    │
│  (Models, Business Logic)               │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│         Infrastructure Layer            │
│  (Database, External APIs)              │
└─────────────────────────────────────────┘
```

### コンポーネント構成

```
app/
├── controllers/
│   └── admin/
│       ├── application_controller.rb      # 管理画面ベース
│       ├── invoices_controller.rb         # 請求書管理
│       ├── invoice_generations_controller.rb  # 請求書一括生成
│       ├── invoice_pdfs_controller.rb     # PDF生成
│       ├── payments_controller.rb         # 入金管理
│       ├── supplies_controller.rb         # 備品管理
│       ├── supply_stocks_controller.rb    # 在庫管理
│       └── reports_controller.rb          # レポート
│
├── models/
│   ├── invoice.rb                         # 請求書モデル
│   ├── invoice_item.rb                    # 請求明細モデル
│   ├── payment.rb                         # 入金モデル
│   ├── supply.rb                          # 備品モデル
│   ├── supply_stock.rb                    # 在庫モデル
│   └── supply_movement.rb                 # 在庫移動モデル
│
├── services/
│   ├── invoice_generator_service.rb       # 請求書生成サービス
│   ├── report_generator_service.rb        # レポート生成サービス
│   ├── unpaid_invoice_checker.rb          # 期限超過チェック
│   └── low_stock_checker.rb               # 在庫不足チェック
│
├── dashboards/
│   ├── invoice_dashboard.rb               # 請求書管理画面定義
│   ├── payment_dashboard.rb               # 入金管理画面定義
│   └── supply_dashboard.rb                # 備品管理画面定義
│
└── views/
    └── admin/
        ├── invoices/
        │   └── pdf.html.erb               # 請求書PDFテンプレート
        └── reports/
            └── index.html.erb             # レポート画面

lib/
└── tasks/
    ├── invoices.rake                      # 請求書関連タスク
    ├── supplies.rake                      # 在庫関連タスク
    └── performance_test_data.rake         # パフォーマンステスト
```

---

## データベース設計

### ER図

```
┌─────────────┐
│  companies  │
└─────────────┘
       │
       │ 1:N
       ↓
┌─────────────┐      1:N     ┌──────────────┐
│  invoices   │──────────────→│invoice_items │
└─────────────┘               └──────────────┘
       │
       │ 1:N
       ↓
┌─────────────┐
│  payments   │
└─────────────┘

┌─────────────┐      1:N     ┌──────────────┐
│  supplies   │──────────────→│supply_stocks │
└─────────────┘               └──────────────┘
       │
       │ 1:N
       ↓
┌──────────────────┐
│supply_movements  │
└──────────────────┘
```

### テーブル定義

#### invoices（請求書）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | - | 主キー |
| company_id | bigint | NO | - | 企業ID（外部キー） |
| invoice_number | string | NO | - | 請求書番号（ユニーク） |
| issue_date | date | NO | - | 発行日 |
| payment_due_date | date | NO | - | 支払期限 |
| billing_period_start | date | NO | - | 請求期間開始 |
| billing_period_end | date | NO | - | 請求期間終了 |
| subtotal | integer | NO | 0 | 小計（円） |
| tax_amount | integer | NO | 0 | 消費税（円） |
| total_amount | integer | NO | 0 | 合計（円） |
| status | string | NO | 'draft' | ステータス（draft/sent/paid/cancelled） |
| payment_status | string | NO | 'unpaid' | 支払ステータス（unpaid/partial/paid/overdue） |
| notes | text | YES | - | 備考 |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス**:
- `index_invoices_on_company_id`
- `index_invoices_on_invoice_number` (unique)
- `index_invoices_on_billing_period_start`
- `index_invoices_on_payment_due_date`
- `index_invoices_on_billing_period_and_status` (composite)

#### invoice_items（請求明細）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | - | 主キー |
| invoice_id | bigint | NO | - | 請求書ID（外部キー） |
| description | string | NO | - | 明細内容 |
| quantity | integer | NO | - | 数量 |
| unit_price | integer | NO | - | 単価（円） |
| amount | integer | NO | - | 金額（円） |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス**:
- `index_invoice_items_on_invoice_id`

#### payments（入金）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | - | 主キー |
| invoice_id | bigint | NO | - | 請求書ID（外部キー） |
| payment_date | date | NO | - | 入金日 |
| amount | integer | NO | - | 入金額（円） |
| payment_method | string | YES | - | 支払方法 |
| reference_number | string | YES | - | 参照番号 |
| notes | text | YES | - | 備考 |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス**:
- `index_payments_on_invoice_id`
- `index_payments_on_payment_date`

#### supplies（備品）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | - | 主キー |
| name | string | NO | - | 備品名 |
| sku | string | NO | - | SKU（ユニーク） |
| category | string | NO | - | カテゴリ |
| unit | string | NO | - | 単位 |
| reorder_point | integer | YES | - | 再注文ポイント |
| storage_guideline | text | YES | - | 保管方法 |
| is_active | boolean | NO | true | 有効フラグ |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス**:
- `index_supplies_on_sku` (unique)
- `index_supplies_on_category`

#### supply_stocks（在庫）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | - | 主キー |
| supply_id | bigint | NO | - | 備品ID（外部キー） |
| location_type | string | YES | - | 拠点タイプ（polymorphic） |
| location_id | bigint | YES | - | 拠点ID（polymorphic） |
| location_name | string | NO | - | 拠点名 |
| quantity | integer | NO | 0 | 在庫数 |
| physical_count | integer | YES | - | 実地棚卸数 |
| last_updated_at | datetime | YES | - | 最終更新日時 |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス**:
- `index_supply_stocks_on_supply_id`
- `index_supply_stocks_on_location` (composite: location_type, location_id)

#### supply_movements（在庫移動）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | - | 主キー |
| supply_id | bigint | NO | - | 備品ID（外部キー） |
| movement_type | string | NO | - | 移動タイプ（入荷/消費/移動） |
| quantity | integer | NO | - | 数量 |
| movement_date | date | NO | - | 移動日 |
| from_location_type | string | YES | - | 移動元タイプ |
| from_location_id | bigint | YES | - | 移動元ID |
| from_location_name | string | YES | - | 移動元名 |
| to_location_type | string | YES | - | 移動先タイプ |
| to_location_id | bigint | YES | - | 移動先ID |
| to_location_name | string | YES | - | 移動先名 |
| notes | text | YES | - | 備考 |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス**:
- `index_supply_movements_on_supply_id`
- `index_supply_movements_on_movement_date`

---

## 主要コンポーネント

### 1. 請求書生成サービス（InvoiceGenerator）

**責務**: 月次請求書の自動生成

**主要メソッド**:
```ruby
class InvoiceGenerator
  def initialize(year:, month:)
    @year = year
    @month = month
    @billing_period_start = Date.new(year, month, 1)
    @billing_period_end = @billing_period_start.end_of_month
  end

  def generate_for_all_companies
    # 全企業の請求書を一括生成
  end

  private

  def generate_invoice_for_company(company)
    # 企業ごとの請求書生成
    # - 対象月の注文データを取得
    # - 請求明細を作成
    # - 金額を計算（小計、消費税、合計）
    # - 請求書番号を自動採番
  end
end
```

**使用箇所**:
- `Admin::InvoiceGenerationsController#create`
- Rakeタスク: `bin/rails invoices:generate_monthly`

### 2. レポート生成サービス（ReportGeneratorService）

**責務**: 月次支払状況レポートの生成

**主要メソッド**:
```ruby
class ReportGeneratorService
  def initialize(year:, month:)
    @year = year
    @month = month
  end

  def generate_monthly_payment_report
    {
      summary: calculate_summary,
      payment_status_breakdown: group_by_payment_status,
      company_breakdown: group_by_company,
      overdue_invoices: find_overdue_invoices,
      recent_payments: find_recent_payments
    }
  end

  private

  def calculate_summary
    # 総請求額、支払済み額、未払い額を計算
  end

  def group_by_payment_status
    # 支払ステータス別に集計
  end
end
```

**パフォーマンス最適化**:
- `includes` を使用してN+1クエリを防止
- データベースインデックスを活用
- 実行時間目標: < 1.0秒

### 3. 期限超過チェッカー（UnpaidInvoiceChecker）

**責務**: 期限超過請求書の自動検出とステータス更新

**主要メソッド**:
```ruby
class UnpaidInvoiceChecker
  def check_overdue
    overdue_invoices = Invoice.where(
      "payment_due_date < ? AND payment_status IN (?)",
      Date.today,
      ['unpaid', 'partial']
    )

    overdue_invoices.each do |invoice|
      invoice.update(payment_status: 'overdue')
    end

    overdue_invoices
  end
end
```

**使用箇所**:
- Rakeタスク: `bin/rails invoices:check_overdue`
- 推奨: 毎日深夜に自動実行（Sidekiq Schedulerで設定）

### 4. 在庫不足チェッカー（LowStockChecker）

**責務**: 在庫不足・在庫切れの検出

**主要メソッド**:
```ruby
class LowStockChecker
  def check_all
    supplies = Supply.active.includes(:supply_stocks)

    low_stock = []
    out_of_stock = []

    supplies.each do |supply|
      total = supply.total_stock
      reorder_point = supply.reorder_point || 0

      if total == 0
        out_of_stock << supply
      elsif total <= reorder_point
        low_stock << supply
      end
    end

    {
      low_stock_items: low_stock,
      low_stock_count: low_stock.count,
      out_of_stock_items: out_of_stock,
      out_of_stock_count: out_of_stock.count
    }
  end
end
```

**使用箇所**:
- Rakeタスク: `bin/rails supplies:check_stock`
- 推奨: 毎日深夜に自動実行

### 5. PDF生成（Prawn）

**責務**: 請求書のPDF出力

**実装場所**: `app/views/admin/invoices/pdf.html.erb`

**主要機能**:
- 企業情報の表示
- 請求明細の表形式表示
- 金額計算（小計、消費税、合計）
- 振込先情報の表示

---

## バッチ処理

### Rakeタスク一覧

#### 請求書関連

```bash
# 月次請求書の一括生成
bin/rails invoices:generate_monthly[2025,12]

# 期限超過チェック
bin/rails invoices:check_overdue
```

#### 在庫関連

```bash
# 在庫不足チェック
bin/rails supplies:check_stock

# 在庫不足一覧表示
bin/rails supplies:low_stock
```

#### パフォーマンステスト

```bash
# テストデータ生成
bin/rails performance:generate_test_data

# ベンチマーク実行
bin/rails performance:benchmark

# テストデータ削除
bin/rails performance:clean_test_data
```

### Sidekiq Schedulerの設定（推奨）

`config/sidekiq.yml` に以下を追加:

```yaml
:schedule:
  check_overdue_invoices:
    cron: '0 1 * * *'  # 毎日深夜1時
    class: CheckOverdueInvoicesJob
    queue: default

  check_low_stock:
    cron: '0 2 * * *'  # 毎日深夜2時
    class: CheckLowStockJob
    queue: default
```

**ジョブクラスの実装例**:

```ruby
# app/jobs/check_overdue_invoices_job.rb
class CheckOverdueInvoicesJob < ApplicationJob
  queue_as :default

  def perform
    checker = UnpaidInvoiceChecker.new
    overdue_invoices = checker.check_overdue

    # メール通知（オプション）
    # AdminMailer.overdue_alert(overdue_invoices).deliver_later
  end
end

# app/jobs/check_low_stock_job.rb
class CheckLowStockJob < ApplicationJob
  queue_as :default

  def perform
    checker = LowStockChecker.new
    result = checker.check_all

    # メール通知（オプション）
    # AdminMailer.low_stock_alert(result).deliver_later
  end
end
```

---

## パフォーマンス最適化

### N+1クエリ対策

#### Administrate Dashboard

```ruby
# app/dashboards/invoice_dashboard.rb
class InvoiceDashboard < Administrate::BaseDashboard
  def self.collection_includes
    [:company, :invoice_items, :payments]
  end
end
```

#### Service Classes

```ruby
# app/services/report_generator_service.rb
def find_invoices
  Invoice.includes(:company, :invoice_items, :payments)
         .where(billing_period_start: @billing_period_start)
         .order(issue_date: :desc)
end
```

### データベースインデックス

**重要なインデックス**:

1. **請求書の請求期間開始日**: レポート生成で頻繁に使用
   ```ruby
   add_index :invoices, :billing_period_start
   ```

2. **請求書の支払期限**: 期限超過チェックで使用
   ```ruby
   add_index :invoices, :payment_due_date
   ```

3. **複合インデックス**: 請求期間と支払ステータス
   ```ruby
   add_index :invoices, [:billing_period_start, :payment_status]
   ```

### パフォーマンス目標

| 処理 | 目標時間 | 実測値（テストデータ） |
|------|----------|----------------------|
| レポート生成 | < 1.0秒 | 0.692秒 ✓ |
| 請求書一覧（100件） | < 0.5秒 | 0.073秒 ✓ |
| 期限超過チェック | < 0.5秒 | 0.151秒 ✓ |
| 在庫不足チェック | < 0.5秒 | 0.345秒 ✓ |

---

## セキュリティ

### 認証・認可

- **管理者認証**: AdminUser モデルで管理
- **基本認証**: 本番環境で HTTP Basic Auth を使用
- **セッション管理**: Rails標準のセッション管理

**実装例**:

```ruby
# app/controllers/admin/application_controller.rb
class Admin::ApplicationController < Administrate::ApplicationController
  before_action :authenticate_admin
  http_basic_authenticate_with name: ENV['ADMIN_USER'], password: ENV['ADMIN_PASSWORD'], if: :production?

  def authenticate_admin
    # 認証ロジック
  end

  def production?
    Rails.env.production?
  end
end
```

### データ保護

1. **環境変数**: 機密情報は環境変数で管理
   ```bash
   # .env
   ADMIN_USER=admin
   ADMIN_PASSWORD=secure_password
   DATABASE_URL=postgres://...
   ```

2. **SQLインジェクション対策**: ActiveRecordのプレースホルダーを使用
   ```ruby
   # Good
   Invoice.where("issue_date >= ?", start_date)

   # Bad
   Invoice.where("issue_date >= '#{start_date}'")
   ```

3. **XSS対策**: ERBのエスケープを活用
   ```erb
   <%= sanitize @invoice.notes %>
   ```

### バックアップ

- **自動バックアップ**: Heroku Postgresの自動バックアップ機能を使用
- **バックアップ頻度**: 毎日
- **保持期間**: 7日間

```bash
# バックアップ取得
heroku pg:backups:capture --app your-app-name

# バックアップ一覧
heroku pg:backups --app your-app-name

# バックアップから復元
heroku pg:backups:restore b001 DATABASE_URL --app your-app-name
```

---

## デプロイメント

### Herokuデプロイ手順

1. **環境変数の設定**

```bash
heroku config:set ADMIN_USER=admin --app your-app-name
heroku config:set ADMIN_PASSWORD=secure_password --app your-app-name
heroku config:set RAILS_ENV=production --app your-app-name
```

2. **デプロイ**

```bash
git push heroku main
```

3. **マイグレーション実行**

```bash
heroku run rails db:migrate --app your-app-name
```

4. **初期データ投入**

```bash
# AdminUserの作成
heroku run rails db:seed --app your-app-name
```

### デプロイチェックリスト

- [ ] 環境変数が設定されている
- [ ] データベースマイグレーションが実行されている
- [ ] 初期データ（AdminUser）が投入されている
- [ ] バックアップが設定されている
- [ ] Sidekiq（バッチ処理）が設定されている（推奨）
- [ ] ログ監視が設定されている
- [ ] エラー通知が設定されている（Sentry等）

### ロールバック手順

```bash
# 前のリリースにロールバック
heroku rollback --app your-app-name

# マイグレーションのロールバック
heroku run rails db:rollback --app your-app-name
```

---

## モニタリング

### ログ監視

```bash
# リアルタイムログ
heroku logs --tail --app your-app-name

# エラーログのみ
heroku logs --tail --source app --app your-app-name | grep ERROR
```

### パフォーマンス監視

**推奨ツール**:
- **New Relic**: APM（Application Performance Monitoring）
- **Skylight**: Rails専用のパフォーマンス監視
- **Heroku Metrics**: 基本的なメトリクス

### エラー通知

**推奨ツール**:
- **Sentry**: エラートラッキング
- **Rollbar**: エラー通知とログ集約

---

## 関連ページ

- [請求書管理操作マニュアル](../manuals/invoice_management.md)
- [入金管理操作マニュアル](../manuals/payment_management.md)
- [在庫管理操作マニュアル](../manuals/inventory_management.md)
- [データ移行手順書](../migration/phase2_data_migration.md)

---

**更新履歴**:
- 2025-12-04: 初版作成
