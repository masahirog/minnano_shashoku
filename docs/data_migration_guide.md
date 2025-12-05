# データ移行手順書

**バージョン:** 2.0
**最終更新日:** 2025-12-05
**対象:** Phase 1-2 スプレッドシート廃止・請求書管理システム導入に伴うデータ移行

---

## 目次

1. [移行概要](#移行概要)
2. [事前準備](#事前準備)
3. [Phase 1: 移行手順](#phase-1-移行手順)
4. [Phase 2: 移行手順](#phase-2-移行手順)
5. [データ検証](#データ検証)
6. [ロールバック手順](#ロールバック手順)
7. [トラブルシューティング](#トラブルシューティング)

---

## 移行概要

### Phase 1: 移行対象データ

1. **企業マスタ** (Companies)
2. **飲食店マスタ** (Restaurants)
3. **メニューマスタ** (Menus)
4. **配送会社マスタ** (Delivery Companies)
5. **既存案件** (Orders) - 過去3ヶ月分
6. **定期スケジュール** (Recurring Orders)

### Phase 2: 移行対象データ

7. **請求書データ** (Invoices) - 過去6ヶ月分
8. **請求明細データ** (Invoice Items)
9. **入金記録** (Payments) - 過去6ヶ月分
10. **在庫データ** (Supplies) - 現在の在庫状況
11. **入出庫記録** (Supply Transactions) - 過去3ヶ月分

### 移行スケジュール

**Phase 1:**
```
Day 1: マスタデータ移行（企業、飲食店、メニュー、配送会社）
Day 2: 既存案件データ移行
Day 3: 定期スケジュール設定
Day 4-7: 動作確認・修正
```

**Phase 2:**
```
Day 1: 既存請求書データ移行
Day 2: 入金記録移行
Day 3: 在庫データ・入出庫記録移行
Day 4-7: 動作確認・修正
```

### 移行方針

- スプレッドシートは読み取り専用として保持（削除しない）
- 移行後1週間は並行運用期間とする
- 問題があればすぐにロールバック可能な状態を維持

---

## 事前準備

### 1. 環境確認

```bash
# データベース接続確認
rails db:migrate:status

# 本番環境へのアクセス確認
heroku logs --tail

# バックアップ確認
heroku pg:backups
```

### 2. スプレッドシートのバックアップ

1. 各スプレッドシートのコピーを作成
   - 企業マスター
   - 飲食店マスター
   - メニューマスター
   - 配送会社マスター
   - 案件マスター
   - 配送予定スケジュール

2. バックアップの命名規則
   ```
   [元のシート名]_backup_YYYYMMDD
   例: 企業マスター_backup_20251203
   ```

3. Google Drive上で専用フォルダに保存
   ```
   /みんなの社食/システム移行/バックアップ/YYYYMMDD/
   ```

### 3. データベースバックアップ

```bash
# ローカル開発環境
pg_dump minnano_shashoku_development > backup_dev_20251203.sql

# 本番環境（Heroku）
heroku pg:backups:capture
heroku pg:backups:download
```

### 4. 移行用Excelファイルの準備

各スプレッドシートをExcel形式（.xlsx）でダウンロード：

```
downloads/
├── companies.xlsx
├── restaurants.xlsx
├── menus.xlsx
├── delivery_companies.xlsx
├── orders.xlsx
└── recurring_orders.xlsx
```

---

## Phase 1: 移行手順

### Day 1: マスタデータ移行

#### Step 1: 企業マスタ移行

1. スプレッドシート「企業マスター」をExcelでダウンロード
2. 管理画面にログイン
3. Companies → 「インポート」をクリック（または手動入力）

**必須項目:**
- 企業名
- 請求先名

**推奨項目:**
- カラー（カレンダー表示用）
- 配送時刻
- 連絡先情報

**インポート確認:**
```bash
# コンソールで確認
rails c
Company.count
# 期待値: スプレッドシートの行数と一致

Company.all.pluck(:name)
# 企業名が全て取り込まれているか確認
```

#### Step 2: 飲食店マスタ移行

1. スプレッドシート「飲食店マスター」をExcelでダウンロード
2. 管理画面で Restaurants → インポートまたは手動入力

**必須項目:**
- 飲食店名
- 契約ステータス
- 最大キャパシティ

**重要項目:**
- capacity_per_day（1日あたりの食数制限）
- max_lots_per_day（1日あたりの案件数制限）
- closed_days（定休日配列）

**定休日の設定方法:**
```ruby
# 例: 日曜・月曜が定休日の場合
restaurant.update(closed_days: ['sunday', 'monday'])
```

**インポート確認:**
```bash
rails c
Restaurant.count
Restaurant.where(capacity_per_day: nil).count
# 0であること（全飲食店にキャパシティが設定されていること）
```

#### Step 3: メニューマスタ移行

1. スプレッドシート「メニューマスター」をExcelでダウンロード
2. 管理画面で Menus → インポートまたは手動入力

**必須項目:**
- メニュー名
- 飲食店（restaurant_id）

**任意項目:**
- カテゴリ
- 写真

**インポート確認:**
```bash
rails c
Menu.count
Menu.joins(:restaurant).count
# 全メニューが飲食店に紐付いていること
```

#### Step 4: 配送会社マスタ移行

1. スプレッドシート「配送会社マスター」をExcelでダウンロード
2. 管理画面で Delivery Companies → インポートまたは手動入力

**必須項目:**
- 配送会社名

**インポート確認:**
```bash
rails c
DeliveryCompany.count
DeliveryCompany.all.pluck(:name)
```

### Day 2: 既存案件データ移行

#### Step 1: 移行対象期間の決定

- 推奨: 過去3ヶ月 + 未来3ヶ月
- 古すぎるデータは移行不要（アーカイブとしてスプレッドシートで保持）

#### Step 2: 案件データの移行

1. スプレッドシート「案件マスター」から対象期間のデータを抽出
2. 管理画面で Orders → 「新規作成」で手動入力、またはインポート機能を使用

**必須項目:**
- company_id
- restaurant_id
- menu_id
- order_type（trial / regular）
- scheduled_date
- default_meal_count
- status（pending / confirmed / completed / cancelled）

**推奨項目:**
- collection_time（回収時刻）
- warehouse_pickup_time（倉庫集荷時刻）
- return_location（返却先）
- equipment_notes（器材メモ）
- is_trial（試食会フラグ）

**一括インポートスクリプト例:**
```ruby
# script/import_orders.rb
require 'csv'

CSV.foreach('data/orders.csv', headers: true) do |row|
  Order.create!(
    company: Company.find_by(name: row['企業名']),
    restaurant: Restaurant.find_by(name: row['飲食店名']),
    menu: Menu.find_by(name: row['メニュー名']),
    order_type: row['区分'] == '試食会' ? 'trial' : 'regular',
    scheduled_date: Date.parse(row['予定日']),
    default_meal_count: row['食数'].to_i,
    status: 'confirmed',
    collection_time: Time.zone.parse(row['回収時刻']),
    warehouse_pickup_time: Time.zone.parse(row['倉庫集荷']),
    is_trial: row['区分'] == '試食会'
  )
end
```

**実行:**
```bash
rails runner script/import_orders.rb
```

**インポート確認:**
```bash
rails c
Order.where('scheduled_date >= ?', 3.months.ago).count
Order.where('scheduled_date >= ?', Date.today).count
# 未来の案件数を確認
```

### Day 3: 定期スケジュール設定

#### Step 1: 定期パターンの抽出

スプレッドシート「配送予定スケジュール」から定期パターンを特定：
- 毎週月曜日に配送
- 隔週火曜日に配送
- など

#### Step 2: 定期スケジュールの登録

管理画面で Recurring Orders → 「新規作成」

**必須項目:**
- company_id
- restaurant_id
- menu_id
- day_of_week（monday, tuesday, etc.）
- frequency（weekly / biweekly）
- default_meal_count
- start_date
- end_date

**登録例:**
```ruby
# 毎週月曜日、テスト企業向け、20食
RecurringOrder.create!(
  company: Company.find_by(name: 'テスト企業'),
  restaurant: Restaurant.find_by(name: 'テスト飲食店'),
  menu: Menu.find_by(name: 'テストメニュー'),
  day_of_week: 'monday',
  frequency: 'weekly',
  default_meal_count: 20,
  start_date: Date.today,
  end_date: Date.today + 3.months
)
```

#### Step 3: 自動生成のテスト

```bash
# 4週間分の案件を生成
rails orders:generate[4]

# 確認
rails c
Order.where('created_at > ?', 1.minute.ago).count
```

---

## Phase 2: 移行手順

### Day 1: 既存請求書データ移行

#### Step 1: 移行対象期間の決定

- 推奨: 過去6ヶ月分の請求書
- 支払済み請求書も含めて移行（入金記録と紐付けるため）

#### Step 2: 請求書データの準備

1. 既存の請求書データをExcel形式で準備
2. 必要な情報を整理
   - 請求書番号
   - 企業名（company_idに変換）
   - 発行日
   - 支払期限
   - 請求期間（開始日・終了日）
   - 小計、消費税、合計金額
   - ステータス（draft/sent/paid）
   - 支払状況（unpaid/partial/paid）

#### Step 3: 請求書インポートスクリプト作成

```ruby
# script/import_invoices.rb
require 'csv'

CSV.foreach('data/invoices.csv', headers: true) do |row|
  company = Company.find_by(name: row['企業名'])
  next unless company

  invoice = Invoice.create!(
    company: company,
    invoice_number: row['請求書番号'],
    issue_date: Date.parse(row['発行日']),
    payment_due_date: Date.parse(row['支払期限']),
    billing_period_start: Date.parse(row['請求期間開始']),
    billing_period_end: Date.parse(row['請求期間終了']),
    subtotal: row['小計'].to_i,
    tax_amount: row['消費税'].to_i,
    total_amount: row['合計金額'].to_i,
    status: row['ステータス'], # draft/sent/paid
    payment_status: row['支払状況'], # unpaid/partial/paid
    notes: row['備考']
  )

  # 請求明細の作成
  # 案件から自動生成する場合
  orders = Order.where(
    company: company,
    scheduled_date: invoice.billing_period_start..invoice.billing_period_end,
    status: 'completed'
  )

  orders.each do |order|
    InvoiceItem.create!(
      invoice: invoice,
      description: "#{order.scheduled_date.strftime('%m/%d')} #{order.restaurant.name} #{order.menu.name}",
      quantity: order.default_meal_count,
      unit_price: 1000, # 実際の単価に置き換え
      amount: order.default_meal_count * 1000
    )
  end

  puts "請求書 #{invoice.invoice_number} を作成しました"
end
```

#### Step 4: インポート実行

```bash
rails runner script/import_invoices.rb
```

#### Step 5: インポート確認

```bash
rails c
Invoice.where('issue_date >= ?', 6.months.ago).count
# 期待値: インポート対象の請求書数

Invoice.joins(:company).count
# 全請求書が企業に紐付いていること

Invoice.joins(:items).distinct.count
# 明細がある請求書の数を確認
```

### Day 2: 入金記録移行

#### Step 1: 入金データの準備

1. 既存の入金記録をExcel形式で準備
2. 必要な情報を整理
   - 請求書番号（invoice_idに変換）
   - 入金日
   - 入金額
   - 入金方法（bank_transfer/credit_card/cash/other）
   - メモ（振込人名義など）

#### Step 2: 入金記録インポートスクリプト作成

```ruby
# script/import_payments.rb
require 'csv'

CSV.foreach('data/payments.csv', headers: true) do |row|
  invoice = Invoice.find_by(invoice_number: row['請求書番号'])
  next unless invoice

  Payment.create!(
    invoice: invoice,
    payment_date: Date.parse(row['入金日']),
    amount: row['入金額'].to_i,
    payment_method: row['入金方法'], # bank_transfer/credit_card/cash/other
    notes: row['メモ']
  )

  puts "入金記録を作成しました: 請求書 #{invoice.invoice_number}, 金額 #{row['入金額']}"
end
```

#### Step 3: インポート実行

```bash
rails runner script/import_payments.rb
```

**注意事項:**
- Paymentモデルのafter_saveコールバックにより、請求書の支払状況が自動更新されます
- 入金額の合計が請求金額に達すると、payment_statusが自動的に'paid'に更新されます

#### Step 4: インポート確認

```bash
rails c

# 入金記録数
Payment.where('payment_date >= ?', 6.months.ago).count

# 支払済み請求書数
Invoice.where(payment_status: 'paid').count

# 入金額の合計確認（特定の請求書）
invoice = Invoice.first
invoice.payments.sum(:amount)
# invoice.total_amountと一致するか確認
```

### Day 3: 在庫データ・入出庫記録移行

#### Step 1: 在庫データの準備

1. 現在の在庫状況をExcel形式で準備
2. 必要な情報を整理
   - 品目名
   - カテゴリ（container/chopsticks/spoon/fork/hand_towel/other）
   - 現在庫数
   - 単位（piece/set/box/other）
   - 最低在庫数
   - メモ

#### Step 2: 在庫インポートスクリプト作成

```ruby
# script/import_supplies.rb
require 'csv'

CSV.foreach('data/supplies.csv', headers: true) do |row|
  Supply.create!(
    name: row['品目名'],
    category: row['カテゴリ'], # container/chopsticks/spoon/fork/hand_towel/other
    current_stock: row['現在庫数'].to_i,
    unit: row['単位'], # piece/set/box/other
    minimum_stock: row['最低在庫数'].to_i,
    notes: row['メモ']
  )

  puts "在庫 #{row['品目名']} を作成しました"
end
```

#### Step 3: 入出庫記録インポートスクリプト作成

```ruby
# script/import_supply_transactions.rb
require 'csv'

CSV.foreach('data/supply_transactions.csv', headers: true) do |row|
  supply = Supply.find_by(name: row['品目名'])
  next unless supply

  SupplyTransaction.create!(
    supply: supply,
    transaction_date: Date.parse(row['記録日']),
    transaction_type: row['タイプ'], # in/out/adjustment
    quantity: row['数量'].to_i,
    notes: row['メモ']
  )

  puts "入出庫記録を作成しました: #{row['品目名']}, #{row['タイプ']}, #{row['数量']}"
end
```

#### Step 4: インポート実行

```bash
# 在庫データ
rails runner script/import_supplies.rb

# 入出庫記録（在庫データ作成後に実行）
rails runner script/import_supply_transactions.rb
```

#### Step 5: インポート確認

```bash
rails c

# 在庫数
Supply.count

# 在庫ステータス別集計
Supply.group(:status).count
# sufficient/low/out_of_stock

# 不足在庫の確認
Supply.where(status: 'out_of_stock').pluck(:name)

# 入出庫記録数
SupplyTransaction.where('transaction_date >= ?', 3.months.ago).count
```

---

## データ検証

### 検証チェックリスト

#### 1. マスタデータの整合性

```bash
rails c

# 企業数
Company.count
# スプレッドシートの行数と一致するか

# 飲食店数
Restaurant.count
# スプレッドシートの行数と一致するか

# メニュー数
Menu.count
# スプレッドシートの行数と一致するか

# 孤立レコードチェック
Menu.where(restaurant_id: nil).count
# 0であること

Order.where(company_id: nil).or(Order.where(restaurant_id: nil)).count
# 0であること
```

#### 2. 案件データの整合性

```bash
# 過去3ヶ月の案件数
Order.where('scheduled_date >= ?', 3.months.ago).count

# 未来の案件数
Order.where('scheduled_date >= ?', Date.today).count

# ステータス別集計
Order.group(:status).count

# キャンセル以外の案件
Order.where.not(status: 'cancelled').count
```

#### 3. 定期スケジュールの検証

```bash
# 定期スケジュール数
RecurringOrder.count

# アクティブな定期スケジュール
RecurringOrder.where('end_date >= ?', Date.today).count

# 各曜日の定期スケジュール数
RecurringOrder.group(:day_of_week).count
```

#### 4. カレンダー表示確認

1. 管理画面でカレンダーにアクセス
2. 過去・現在・未来の案件が正しく表示されるか確認
3. 企業別カラーが正しく表示されるか確認
4. メニュー重複警告が正しく表示されるか確認

#### 5. 配送シート出力確認

1. 配送シート画面にアクセス
2. PDF出力が正常に動作するか確認
3. 日本語が文字化けしていないか確認
4. 全ての情報が含まれているか確認

#### 6. 請求書データの検証（Phase 2）

```bash
rails c

# 請求書数
Invoice.where('issue_date >= ?', 6.months.ago).count

# ステータス別集計
Invoice.group(:status).count
# draft/sent/paid/overdue

# 支払状況別集計
Invoice.group(:payment_status).count
# unpaid/partial/paid

# 明細がある請求書
Invoice.joins(:items).distinct.count
# 全請求書に明細があること

# 孤立レコードチェック
Invoice.where(company_id: nil).count
# 0であること
```

#### 7. 入金記録の検証（Phase 2）

```bash
# 入金記録数
Payment.where('payment_date >= ?', 6.months.ago).count

# 入金方法別集計
Payment.group(:payment_method).count
# bank_transfer/credit_card/cash/other

# 請求書と入金額の整合性
Invoice.where(payment_status: 'paid').each do |invoice|
  paid_amount = invoice.payments.sum(:amount)
  unless paid_amount == invoice.total_amount
    puts "不整合: 請求書 #{invoice.invoice_number}, 請求額 #{invoice.total_amount}, 入金額 #{paid_amount}"
  end
end
```

#### 8. 在庫データの検証（Phase 2）

```bash
# 在庫数
Supply.count

# ステータス別集計
Supply.group(:status).count
# sufficient/low/out_of_stock

# 在庫アラート
Supply.where('current_stock < minimum_stock').count
# statusが'low'または'out_of_stock'のもの

# 入出庫記録の整合性
Supply.all.each do |supply|
  transactions_total = supply.transactions.sum do |t|
    t.transaction_type == 'in' ? t.quantity : -t.quantity
  end
  # current_stockと一致するか確認（初期在庫を考慮）
end
```

#### 9. 請求書PDF出力確認（Phase 2）

1. 管理画面で請求書詳細にアクセス
2. 「PDF出力」ボタンをクリック
3. PDFが正常に生成されるか確認
4. 日本語が文字化けしていないか確認
5. 全ての情報（請求書番号、発行日、支払期限、明細、合計金額）が含まれているか確認

---

## ロールバック手順

詳細は `docs/rollback_guide.md` を参照

---

## トラブルシューティング

### Q1. インポート中にエラーが発生

**エラー例:** "Validation failed: Restaurant must exist"

**原因:**
- 外部キー参照先のレコードが存在しない

**対処:**
1. 参照先のマスタデータを先に移行
2. スプレッドシートとデータベースの名前の不一致を確認

### Q2. 日付のフォーマットエラー

**エラー例:** "Invalid date format"

**対処:**
```ruby
# 日付パースの修正
Date.parse(row['予定日'])
# または
Date.strptime(row['予定日'], '%Y/%m/%d')
```

### Q3. 文字コードエラー

**エラー例:** "Invalid byte sequence in UTF-8"

**対処:**
```ruby
CSV.foreach('data.csv', headers: true, encoding: 'UTF-8') do |row|
  # ...
end

# または
CSV.foreach('data.csv', headers: true, encoding: 'Shift_JIS:UTF-8') do |row|
  # ...
end
```

### Q4. キャパシティオーバーで案件を作成できない

**対処:**
1. 一時的にバリデーションをスキップ
```ruby
order = Order.new(attributes)
order.save(validate: false)
```

2. 後で手動で調整

### Q5. 定期スケジュールが生成されない

**確認項目:**
- start_dateとend_dateが正しいか
- day_of_weekのフォーマットが正しいか（'monday', 'tuesday', etc.）
- 飲食店の定休日に該当していないか

---

## 移行完了チェックリスト

### Phase 1

- [ ] 企業マスタ移行完了
- [ ] 飲食店マスタ移行完了
- [ ] メニューマスタ移行完了
- [ ] 配送会社マスタ移行完了
- [ ] 既存案件データ移行完了
- [ ] 定期スケジュール設定完了
- [ ] データ検証完了
- [ ] カレンダー表示確認
- [ ] 配送シート出力確認
- [ ] PDF出力確認
- [ ] スタッフ向け説明会実施
- [ ] 1週間の並行運用期間設定
- [ ] ロールバック手順確認
- [ ] スプレッドシートを読み取り専用に設定

### Phase 2

- [ ] 既存請求書データ移行完了
- [ ] 請求明細データ移行完了
- [ ] 入金記録移行完了
- [ ] 在庫データ移行完了
- [ ] 入出庫記録移行完了
- [ ] 請求書データ検証完了
- [ ] 入金記録検証完了
- [ ] 在庫データ検証完了
- [ ] 請求書PDF出力確認
- [ ] 月次請求書自動生成テスト
- [ ] 未払い請求書アラート確認
- [ ] 在庫アラート確認
- [ ] スタッフ向け追加機能説明会実施
- [ ] 1週間の実運用テスト
- [ ] ロールバック手順確認
