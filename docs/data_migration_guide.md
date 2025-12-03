# データ移行手順書

**バージョン:** 1.0
**最終更新日:** 2025-12-03
**対象:** Phase 1 MVP スプレッドシート廃止に伴うデータ移行

---

## 目次

1. [移行概要](#移行概要)
2. [事前準備](#事前準備)
3. [移行手順](#移行手順)
4. [データ検証](#データ検証)
5. [ロールバック手順](#ロールバック手順)
6. [トラブルシューティング](#トラブルシューティング)

---

## 移行概要

### 移行対象データ

1. **企業マスタ** (Companies)
2. **飲食店マスタ** (Restaurants)
3. **メニューマスタ** (Menus)
4. **配送会社マスタ** (Delivery Companies)
5. **既存案件** (Orders) - 過去3ヶ月分
6. **定期スケジュール** (Recurring Orders)

### 移行スケジュール

```
Day 1: マスタデータ移行（企業、飲食店、メニュー、配送会社）
Day 2: 既存案件データ移行
Day 3: 定期スケジュール設定
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

## 移行手順

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
