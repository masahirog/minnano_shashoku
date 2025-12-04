# Phase 2 データ移行手順書

**Phase 2: 請求・支払い管理、在庫管理システム**

---

## 目次

1. [概要](#概要)
2. [移行前の準備](#移行前の準備)
3. [請求書データの移行](#請求書データの移行)
4. [入金データの移行](#入金データの移行)
5. [在庫データの初期設定](#在庫データの初期設定)
6. [データ検証](#データ検証)
7. [ロールバック手順](#ロールバック手順)
8. [トラブルシューティング](#トラブルシューティング)

---

## 概要

Phase 2では以下のデータを新システムに移行・初期設定します。

### 移行対象データ

- **請求書データ**: 既存の請求書情報（過去6ヶ月分推奨）
- **入金データ**: 既存の入金履歴
- **在庫データ**: 備品マスタと初期在庫

### 移行方針

- **最小限の移行**: 過去6ヶ月分の請求・入金データのみ
- **段階的移行**: 請求書 → 入金 → 在庫の順に実施
- **検証重視**: 各ステップで必ずデータ検証を実施
- **ロールバック可能**: 問題発生時は即座にロールバック

---

## 移行前の準備

### 1. バックアップの取得

```bash
# 本番環境のデータベースバックアップ
heroku pg:backups:capture --app your-app-name

# ローカルにダウンロード
heroku pg:backups:download --app your-app-name
```

### 2. 移行データの抽出

既存システムから以下のデータをCSV形式で抽出します。

#### 請求書データ（invoices.csv）

| カラム | 説明 | 例 |
|--------|------|-----|
| company_name | 企業名 | 株式会社サンプル |
| issue_date | 発行日 | 2025-07-01 |
| payment_due_date | 支払期限 | 2025-07-31 |
| billing_period_start | 請求期間開始 | 2025-06-01 |
| billing_period_end | 請求期間終了 | 2025-06-30 |
| subtotal | 小計 | 100000 |
| tax_amount | 消費税 | 10000 |
| total_amount | 合計 | 110000 |
| status | ステータス | sent |
| notes | 備考 | - |

#### 請求明細データ（invoice_items.csv）

| カラム | 説明 | 例 |
|--------|------|-----|
| invoice_company_name | 請求書の企業名 | 株式会社サンプル |
| invoice_issue_date | 請求書発行日 | 2025-07-01 |
| description | 明細内容 | 試食会サービス Aプラン |
| quantity | 数量 | 20 |
| unit_price | 単価 | 649 |
| amount | 金額 | 12980 |

#### 入金データ（payments.csv）

| カラム | 説明 | 例 |
|--------|------|-----|
| invoice_company_name | 請求書の企業名 | 株式会社サンプル |
| invoice_issue_date | 請求書発行日 | 2025-07-01 |
| payment_date | 入金日 | 2025-07-15 |
| amount | 入金額 | 110000 |
| payment_method | 支払方法 | 銀行振込 |
| reference_number | 参照番号 | 123456789 |
| notes | 備考 | - |

#### 備品マスタデータ（supplies.csv）

| カラム | 説明 | 例 |
|--------|------|-----|
| name | 備品名 | プラスチック容器（大） |
| sku | SKU | CONT-L-001 |
| category | カテゴリ | 使い捨て備品 |
| unit | 単位 | 個 |
| reorder_point | 再注文ポイント | 50 |
| storage_guideline | 保管方法 | 直射日光を避けて保管 |
| is_active | 有効フラグ | true |

#### 在庫データ（supply_stocks.csv）

| カラム | 説明 | 例 |
|--------|------|-----|
| supply_sku | 備品SKU | CONT-L-001 |
| location_type | 拠点タイプ | - |
| location_id | 拠点ID | - |
| location_name | 拠点名 | 本社 |
| quantity | 在庫数 | 100 |

### 3. データの事前確認

```bash
# CSVファイルの文字コード確認（UTF-8であること）
file -I invoices.csv

# CSVファイルの行数確認
wc -l invoices.csv
wc -l invoice_items.csv
wc -l payments.csv
wc -l supplies.csv
wc -l supply_stocks.csv
```

---

## 請求書データの移行

### 1. 移行スクリプトの作成

`lib/tasks/import_invoices.rake` を作成します：

```ruby
namespace :import do
  desc "請求書データをCSVからインポート"
  task invoices: :environment do
    require 'csv'

    csv_file = Rails.root.join('tmp', 'invoices.csv')

    unless File.exist?(csv_file)
      puts "エラー: #{csv_file} が見つかりません"
      exit 1
    end

    success_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
        begin
          company = Company.find_by(name: row['company_name'])
          unless company
            errors << "企業が見つかりません: #{row['company_name']}"
            error_count += 1
            next
          end

          invoice = Invoice.create!(
            company: company,
            issue_date: Date.parse(row['issue_date']),
            payment_due_date: Date.parse(row['payment_due_date']),
            billing_period_start: Date.parse(row['billing_period_start']),
            billing_period_end: Date.parse(row['billing_period_end']),
            subtotal: row['subtotal'].to_i,
            tax_amount: row['tax_amount'].to_i,
            total_amount: row['total_amount'].to_i,
            status: row['status'] || 'sent',
            notes: row['notes']
          )

          success_count += 1
          puts "✓ 請求書作成: #{company.name} - #{invoice.invoice_number}"
        rescue => e
          errors << "行 #{$.}: #{e.message}"
          error_count += 1
        end
      end

      puts "\n" + "=" * 60
      puts "請求書インポート完了"
      puts "成功: #{success_count}件"
      puts "失敗: #{error_count}件"

      if errors.any?
        puts "\nエラー詳細:"
        errors.each { |error| puts "  - #{error}" }
      end
      puts "=" * 60
    end
  end
end
```

### 2. 移行の実行

```bash
# CSVファイルを tmp/ ディレクトリに配置
cp invoices.csv tmp/

# 移行実行（開発環境で先にテスト）
RAILS_ENV=development bin/rails import:invoices

# 本番環境で実行
RAILS_ENV=production bin/rails import:invoices
```

### 3. 請求明細の移行

`lib/tasks/import_invoice_items.rake` を作成：

```ruby
namespace :import do
  desc "請求明細データをCSVからインポート"
  task invoice_items: :environment do
    require 'csv'

    csv_file = Rails.root.join('tmp', 'invoice_items.csv')

    success_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
        begin
          company = Company.find_by(name: row['invoice_company_name'])
          invoice = company.invoices.find_by(issue_date: Date.parse(row['invoice_issue_date']))

          unless invoice
            errors << "請求書が見つかりません: #{row['invoice_company_name']} - #{row['invoice_issue_date']}"
            error_count += 1
            next
          end

          invoice.invoice_items.create!(
            description: row['description'],
            quantity: row['quantity'].to_i,
            unit_price: row['unit_price'].to_i,
            amount: row['amount'].to_i
          )

          success_count += 1
        rescue => e
          errors << "行 #{$.}: #{e.message}"
          error_count += 1
        end
      end

      puts "\n" + "=" * 60
      puts "請求明細インポート完了"
      puts "成功: #{success_count}件"
      puts "失敗: #{error_count}件"

      if errors.any?
        puts "\nエラー詳細:"
        errors.each { |error| puts "  - #{error}" }
      end
      puts "=" * 60
    end
  end
end
```

実行：

```bash
cp invoice_items.csv tmp/
RAILS_ENV=production bin/rails import:invoice_items
```

---

## 入金データの移行

### 1. 移行スクリプトの作成

`lib/tasks/import_payments.rake` を作成：

```ruby
namespace :import do
  desc "入金データをCSVからインポート"
  task payments: :environment do
    require 'csv'

    csv_file = Rails.root.join('tmp', 'payments.csv')

    success_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
        begin
          company = Company.find_by(name: row['invoice_company_name'])
          invoice = company.invoices.find_by(issue_date: Date.parse(row['invoice_issue_date']))

          unless invoice
            errors << "請求書が見つかりません: #{row['invoice_company_name']} - #{row['invoice_issue_date']}"
            error_count += 1
            next
          end

          payment = invoice.payments.create!(
            payment_date: Date.parse(row['payment_date']),
            amount: row['amount'].to_i,
            payment_method: row['payment_method'],
            reference_number: row['reference_number'],
            notes: row['notes']
          )

          success_count += 1
          puts "✓ 入金作成: #{company.name} - #{payment.amount}円"
        rescue => e
          errors << "行 #{$.}: #{e.message}"
          error_count += 1
        end
      end

      puts "\n" + "=" * 60
      puts "入金インポート完了"
      puts "成功: #{success_count}件"
      puts "失敗: #{error_count}件"

      if errors.any?
        puts "\nエラー詳細:"
        errors.each { |error| puts "  - #{error}" }
      end
      puts "=" * 60

      # 入金後、全請求書の支払ステータスを更新
      puts "\n請求書の支払ステータスを更新中..."
      Invoice.find_each do |invoice|
        invoice.update_payment_status
      end
      puts "✓ 支払ステータス更新完了"
    end
  end
end
```

### 2. 実行

```bash
cp payments.csv tmp/
RAILS_ENV=production bin/rails import:payments
```

---

## 在庫データの初期設定

### 1. 備品マスタの移行

`lib/tasks/import_supplies.rake` を作成：

```ruby
namespace :import do
  desc "備品マスタをCSVからインポート"
  task supplies: :environment do
    require 'csv'

    csv_file = Rails.root.join('tmp', 'supplies.csv')

    success_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
        begin
          supply = Supply.create!(
            name: row['name'],
            sku: row['sku'],
            category: row['category'],
            unit: row['unit'],
            reorder_point: row['reorder_point']&.to_i,
            storage_guideline: row['storage_guideline'],
            is_active: row['is_active'] == 'true'
          )

          success_count += 1
          puts "✓ 備品作成: #{supply.name} (#{supply.sku})"
        rescue => e
          errors << "行 #{$.}: #{e.message}"
          error_count += 1
        end
      end

      puts "\n" + "=" * 60
      puts "備品マスタインポート完了"
      puts "成功: #{success_count}件"
      puts "失敗: #{error_count}件"

      if errors.any?
        puts "\nエラー詳細:"
        errors.each { |error| puts "  - #{error}" }
      end
      puts "=" * 60
    end
  end
end
```

### 2. 在庫データの移行

`lib/tasks/import_supply_stocks.rake` を作成：

```ruby
namespace :import do
  desc "在庫データをCSVからインポート"
  task supply_stocks: :environment do
    require 'csv'

    csv_file = Rails.root.join('tmp', 'supply_stocks.csv')

    success_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
        begin
          supply = Supply.find_by(sku: row['supply_sku'])

          unless supply
            errors << "備品が見つかりません: #{row['supply_sku']}"
            error_count += 1
            next
          end

          # location_idがある場合はpolymorphicに対応
          location_id = row['location_id'].present? ? row['location_id'].to_i : nil
          location_type = row['location_type'].presence

          stock = supply.supply_stocks.create!(
            location_type: location_type,
            location_id: location_id,
            location_name: row['location_name'],
            quantity: row['quantity'].to_i
          )

          success_count += 1
          puts "✓ 在庫作成: #{supply.name} - #{stock.location_name} (#{stock.quantity}#{supply.unit})"
        rescue => e
          errors << "行 #{$.}: #{e.message}"
          error_count += 1
        end
      end

      puts "\n" + "=" * 60
      puts "在庫データインポート完了"
      puts "成功: #{success_count}件"
      puts "失敗: #{error_count}件"

      if errors.any?
        puts "\nエラー詳細:"
        errors.each { |error| puts "  - #{error}" }
      end
      puts "=" * 60
    end
  end
end
```

### 3. 実行

```bash
# 備品マスタのインポート
cp supplies.csv tmp/
RAILS_ENV=production bin/rails import:supplies

# 在庫データのインポート
cp supply_stocks.csv tmp/
RAILS_ENV=production bin/rails import:supply_stocks
```

---

## データ検証

### 1. 請求書データの検証

```bash
# Rails consoleで実行
RAILS_ENV=production bin/rails console
```

```ruby
# 1. 請求書数の確認
puts "総請求書数: #{Invoice.count}件"

# 2. 企業ごとの請求書数
Company.active.each do |company|
  count = company.invoices.count
  puts "#{company.name}: #{count}件"
end

# 3. ステータス別の請求書数
Invoice.group(:status).count.each do |status, count|
  puts "#{status}: #{count}件"
end

# 4. 支払ステータス別の請求書数
Invoice.group(:payment_status).count.each do |status, count|
  puts "#{status}: #{count}件"
end

# 5. 金額の整合性チェック
invoices_with_mismatch = Invoice.where.not(
  "total_amount = subtotal + tax_amount"
).count
puts "金額不整合: #{invoices_with_mismatch}件"

# 6. 請求明細のない請求書
invoices_without_items = Invoice.left_joins(:invoice_items)
                                .where(invoice_items: { id: nil })
                                .count
puts "明細なし請求書: #{invoices_without_items}件"
```

### 2. 入金データの検証

```ruby
# 1. 入金総数
puts "総入金数: #{Payment.count}件"

# 2. 入金合計
total_payments = Payment.sum(:amount)
puts "入金合計: #{total_payments.to_s(:delimited)}円"

# 3. 支払方法別の入金数
Payment.group(:payment_method).count.each do |method, count|
  puts "#{method}: #{count}件"
end

# 4. 残高超過チェック
payments_over_balance = Payment.joins(:invoice).where(
  "payments.amount > invoices.total_amount"
).count
puts "残高超過入金: #{payments_over_balance}件"

# 5. 請求書ごとの入金合計と請求額の比較
Invoice.includes(:payments).find_each do |invoice|
  paid_amount = invoice.payments.sum(:amount)
  if paid_amount > invoice.total_amount
    puts "警告: 請求書 #{invoice.invoice_number} で過払い (#{paid_amount} > #{invoice.total_amount})"
  end
end
```

### 3. 在庫データの検証

```ruby
# 1. 備品総数
puts "総備品数: #{Supply.count}件"
puts "有効備品数: #{Supply.active.count}件"

# 2. カテゴリ別の備品数
Supply.group(:category).count.each do |category, count|
  puts "#{category}: #{count}件"
end

# 3. 在庫ロケーション総数
puts "総在庫ロケーション: #{SupplyStock.count}件"

# 4. 在庫なし備品
supplies_without_stock = Supply.left_joins(:supply_stocks)
                               .where(supply_stocks: { id: nil })
                               .count
puts "在庫レコードなし備品: #{supplies_without_stock}件"

# 5. マイナス在庫チェック
negative_stocks = SupplyStock.where("quantity < 0").count
puts "マイナス在庫: #{negative_stocks}件"

# 6. 在庫不足チェック
checker = LowStockChecker.new
result = checker.check_all
puts "在庫不足: #{result[:low_stock_count]}件"
puts "在庫切れ: #{result[:out_of_stock_count]}件"
```

### 4. 検証レポートの出力

```ruby
# 検証レポートを生成
File.open(Rails.root.join('tmp', 'migration_report.txt'), 'w') do |f|
  f.puts "=" * 60
  f.puts "Phase 2 データ移行検証レポート"
  f.puts "実行日時: #{Time.current}"
  f.puts "=" * 60

  f.puts "\n【請求書データ】"
  f.puts "総請求書数: #{Invoice.count}件"
  f.puts "下書き: #{Invoice.draft.count}件"
  f.puts "送信済み: #{Invoice.sent.count}件"
  f.puts "支払済み: #{Invoice.paid_status.count}件"

  f.puts "\n【入金データ】"
  f.puts "総入金数: #{Payment.count}件"
  f.puts "入金合計: #{Payment.sum(:amount).to_s(:delimited)}円"

  f.puts "\n【在庫データ】"
  f.puts "総備品数: #{Supply.count}件"
  f.puts "総在庫ロケーション: #{SupplyStock.count}件"
  f.puts "総在庫数: #{SupplyStock.sum(:quantity)}個"

  f.puts "\n【エラーチェック】"
  f.puts "金額不整合請求書: #{Invoice.where.not('total_amount = subtotal + tax_amount').count}件"
  f.puts "明細なし請求書: #{Invoice.left_joins(:invoice_items).where(invoice_items: { id: nil }).count}件"
  f.puts "マイナス在庫: #{SupplyStock.where('quantity < 0').count}件"

  f.puts "\n" + "=" * 60
end

puts "検証レポートを tmp/migration_report.txt に出力しました"
```

---

## ロールバック手順

### 1. データベースバックアップからの復元

```bash
# Heroku本番環境の場合
# 1. 最新のバックアップを確認
heroku pg:backups --app your-app-name

# 2. バックアップから復元
heroku pg:backups:restore b001 DATABASE_URL --app your-app-name --confirm your-app-name
```

### 2. 個別データの削除

インポートしたデータのみを削除する場合：

```ruby
# Rails consoleで実行
RAILS_ENV=production bin/rails console

# 特定期間の請求書を削除
start_date = Date.parse('2025-06-01')
end_date = Date.parse('2025-12-31')

invoices_to_delete = Invoice.where(billing_period_start: start_date..end_date)
puts "削除対象請求書: #{invoices_to_delete.count}件"

# 確認後、削除実行
# invoices_to_delete.destroy_all

# 特定のSKUパターンの備品を削除
supplies_to_delete = Supply.where("sku LIKE ?", "IMPORTED-%")
puts "削除対象備品: #{supplies_to_delete.count}件"

# 確認後、削除実行
# supplies_to_delete.destroy_all
```

### 3. トランザクションロールバック

移行スクリプトは `ActiveRecord::Base.transaction` で囲まれているため、エラー発生時は自動的にロールバックされます。

手動でロールバックする場合：

```ruby
ActiveRecord::Base.transaction do
  # 削除処理
  Invoice.where(billing_period_start: start_date..end_date).destroy_all
  Supply.where("sku LIKE ?", "IMPORTED-%").destroy_all

  # 確認
  puts "ロールバック完了"
  puts "請求書数: #{Invoice.count}件"
  puts "備品数: #{Supply.count}件"
end
```

---

## トラブルシューティング

### Q1. CSVインポート時に文字化けする

**原因**: 文字コードがUTF-8ではない

**解決方法**:
```bash
# 文字コードを確認
file -I invoices.csv

# Shift-JISからUTF-8に変換
iconv -f SHIFT-JIS -t UTF-8 invoices.csv > invoices_utf8.csv
```

### Q2. 企業が見つからないエラー

**エラー**: "企業が見つかりません: ○○○"

**原因**: CSVの企業名とデータベースの企業名が一致しない

**解決方法**:
```ruby
# Rails consoleで企業名を確認
Company.pluck(:name)

# CSVの企業名を確認
require 'csv'
CSV.foreach('tmp/invoices.csv', headers: true) { |row| puts row['company_name'] }

# 必要に応じて、CSVの企業名を修正
```

### Q3. 請求書番号が重複する

**エラー**: "Validation failed: Invoice number has already been taken"

**原因**: 既に同じ請求書番号が存在する

**解決方法**:
```ruby
# 既存の請求書番号を確認
Invoice.pluck(:invoice_number)

# 重複している請求書を削除または invoice_number を変更
```

### Q4. 金額の不整合

**エラー**: "total_amount が subtotal + tax_amount と一致しません"

**解決方法**:
```ruby
# 不整合のある請求書を検出
Invoice.where.not("total_amount = subtotal + tax_amount").each do |invoice|
  puts "請求書 #{invoice.invoice_number}:"
  puts "  小計: #{invoice.subtotal}"
  puts "  消費税: #{invoice.tax_amount}"
  puts "  合計: #{invoice.total_amount}"
  puts "  期待値: #{invoice.subtotal + invoice.tax_amount}"

  # 修正
  invoice.update_columns(
    total_amount: invoice.subtotal + invoice.tax_amount
  )
end
```

### Q5. 大量データのインポートが遅い

**原因**: 1件ずつINSERTしている

**解決方法**: バルクインサートを使用

```ruby
# activerecord-import gemを使用
require 'activerecord-import'

invoices = []
CSV.foreach(csv_file, headers: true) do |row|
  company = Company.find_by(name: row['company_name'])
  next unless company

  invoices << Invoice.new(
    company: company,
    issue_date: Date.parse(row['issue_date']),
    # ... その他の属性
  )

  # 1000件ごとにバルクインサート
  if invoices.size >= 1000
    Invoice.import invoices
    invoices.clear
  end
end

# 残りをインサート
Invoice.import invoices if invoices.any?
```

---

## ベストプラクティス

### 移行の推奨手順

1. **開発環境でテスト**: 本番実行前に必ず開発環境でテスト
2. **小規模データで検証**: 10-20件の小規模データで動作確認
3. **段階的移行**: 請求書 → 入金 → 在庫の順に実施
4. **各ステップで検証**: 移行後、必ずデータ検証を実施
5. **バックアップ取得**: 移行前に必ずバックアップ
6. **ロールバック準備**: 問題発生時の手順を事前に確認

### データ品質チェックリスト

- [ ] CSVファイルの文字コードがUTF-8
- [ ] 必須項目がすべて入力されている
- [ ] 日付形式が正しい（YYYY-MM-DD）
- [ ] 金額が数値型
- [ ] 企業名がデータベースと一致
- [ ] SKUが重複していない
- [ ] 外部キー関係が正しい

---

## 関連ページ

- [請求書管理操作マニュアル](../manuals/invoice_management.md)
- [入金管理操作マニュアル](../manuals/payment_management.md)
- [在庫管理操作マニュアル](../manuals/inventory_management.md)
- [システム構成ドキュメント](../architecture/phase2_system_architecture.md)

---

**更新履歴**:
- 2025-12-04: 初版作成
