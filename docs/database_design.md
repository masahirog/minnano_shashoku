# データベース設計（Phase 1追加分）

## 新規テーブル

### 1. recurring_orders（定期スケジュール）

週1回〜の定期的な案件スケジュールを管理するテーブル。
このテーブルから実際のOrderレコードを自動生成します。

```ruby
create_table :recurring_orders do |t|
  t.references :company, null: false, foreign_key: true
  t.references :restaurant, null: false, foreign_key: true
  t.references :menu, null: true, foreign_key: true
  t.references :delivery_company, null: true, foreign_key: true

  # スケジュール設定
  t.integer :day_of_week, null: false  # 0:日曜 〜 6:土曜
  t.string :frequency, null: false, default: 'weekly'  # 'weekly', 'biweekly', 'monthly'
  t.date :start_date, null: false
  t.date :end_date  # null = 無期限

  # 案件情報
  t.integer :default_meal_count, null: false, default: 50
  t.time :delivery_time, null: false
  t.time :pickup_time

  # 配送フロー関連（業務マニュアルに基づく追加）
  t.boolean :is_trial, null: false, default: false  # 試食会か本導入か
  t.time :collection_time  # 器材回収時刻（企業から）
  t.time :warehouse_pickup_time  # 倉庫での器材集荷時刻
  t.string :return_location, default: 'warehouse'  # 器材返却先（'warehouse'/'restaurant'）
  t.text :equipment_notes  # 器材メモ（Phase 1簡易対応）

  # ステータス
  t.boolean :is_active, null: false, default: true
  t.string :status, null: false, default: 'active'  # 'active', 'paused', 'completed'

  # メモ
  t.text :notes

  t.timestamps
end

add_index :recurring_orders, [:company_id, :day_of_week]
add_index :recurring_orders, [:restaurant_id, :day_of_week]
add_index :recurring_orders, :start_date
add_index :recurring_orders, :is_active
```

### 2. 既存テーブルへの追加カラム

#### ordersテーブル

```ruby
add_column :orders, :recurring_order_id, :bigint
add_foreign_key :orders, :recurring_orders

add_column :orders, :menu_confirmed, :boolean, default: false
add_column :orders, :meal_count_confirmed, :boolean, default: false
add_column :orders, :confirmation_deadline, :datetime

# 配送フロー関連（業務マニュアルに基づく追加）
add_column :orders, :is_trial, :boolean, default: false  # 試食会か本導入か
add_column :orders, :collection_time, :time  # 器材回収時刻（企業から）
add_column :orders, :warehouse_pickup_time, :time  # 倉庫での器材集荷時刻
add_column :orders, :return_location, :string  # 器材返却先（'warehouse'/'restaurant'）
add_column :orders, :equipment_notes, :text  # 器材メモ（Phase 1簡易対応）

add_index :orders, :recurring_order_id
add_index :orders, :delivery_date
add_index :orders, :is_trial
```

#### restaurantsテーブル

```ruby
add_column :restaurants, :capacity_per_day, :integer, default: 100  # 1日の製造キャパ（食数）
add_column :restaurants, :max_lots_per_day, :integer, default: 2  # 1日の最大ロット数
add_column :restaurants, :pickup_time_earliest, :time  # 集荷可能最早時間
add_column :restaurants, :pickup_time_latest, :time  # 集荷可能最遅時間
add_column :restaurants, :regular_holiday, :string  # '0,6' = 日曜・土曜
```

#### companiesテーブル

```ruby
add_column :companies, :delivery_time_preferred, :time  # 希望納品時間
add_column :companies, :delivery_time_earliest, :time  # 納品可能最早
add_column :companies, :delivery_time_latest, :time  # 納品可能最遅
add_column :companies, :meal_count_min, :integer  # 最小食数
add_column :companies, :meal_count_max, :integer  # 最大食数
```

## マイグレーション実行順序

```bash
# Phase 1-1: recurring_ordersテーブル作成
rails g migration CreateRecurringOrders

# Phase 1-2: 既存テーブル拡張
rails g migration AddScheduleFieldsToOrders
rails g migration AddCapacityFieldsToRestaurants
rails g migration AddDeliveryFieldsToCompanies

# 実行
rails db:migrate
```

## バリデーション設計

### RecurringOrder

- `company_id`: presence
- `restaurant_id`: presence
- `day_of_week`: inclusion in 0..6
- `frequency`: inclusion in ['weekly', 'biweekly', 'monthly']
- `start_date`: presence
- `end_date`: greater than start_date（if present）
- `default_meal_count`: numericality, multiple of 50
- `delivery_time`: presence
- カスタム検証:
  - 飲食店の定休日チェック
  - 飲食店のキャパオーバーチェック
  - メニュー重複チェック（同じ企業に同じ週に同じメニューが複数回）

### Order（既存＋追加）

既存バリデーションに加えて：
- `delivery_date`: 飲食店の定休日でないこと
- `meal_count`: 飲食店の1日キャパ以内
- カスタム検証:
  - 同じ日に同じ企業へ別メニューが納品される場合のアラート

## インデックス戦略

### よく使われる検索パターン

1. **カレンダー表示**
   ```sql
   SELECT * FROM orders WHERE delivery_date BETWEEN ? AND ?
   ORDER BY delivery_date, delivery_time
   ```
   → `orders(delivery_date, delivery_time)` 複合インデックス

2. **企業別スケジュール**
   ```sql
   SELECT * FROM orders WHERE company_id = ? AND delivery_date >= ?
   ```
   → `orders(company_id, delivery_date)` 複合インデックス

3. **飲食店別スケジュール**
   ```sql
   SELECT * FROM recurring_orders WHERE restaurant_id = ? AND is_active = true
   ```
   → `recurring_orders(restaurant_id, is_active)` 複合インデックス

4. **メニュー重複チェック**
   ```sql
   SELECT * FROM orders WHERE company_id = ? AND menu_id = ? AND delivery_date BETWEEN ? AND ?
   ```
   → `orders(company_id, menu_id, delivery_date)` 複合インデックス

## データ整合性

### 制約

- `recurring_orders.end_date >= start_date`
- `orders.meal_count % 50 = 0` （50食単位）
- `orders.delivery_date` は未来日付のみ編集可能
- 削除は論理削除（deleted_atカラム追加検討）

### カスケード

- RecurringOrder削除時 → 未来のOrder削除（過去は保持）
- Restaurant削除時 → RecurringOrder無効化
- Company削除時 → RecurringOrder無効化

## Phase 2以降で追加予定のテーブル

Phase 1では作成せず、Phase 2で実装：

### 請求・支払い関連
- `invoices` - 請求書
- `invoice_items` - 請求明細
- `payment_notices` - 支払通知書
- `trouble_adjustments` - トラブル調整
- `paypay_transactions` - PayPay取込

### 配送・器材管理関連（業務マニュアルに基づく追加）
- `warehouses` - 倉庫マスタ（千代田区倉庫等の管理）
- `equipments` - 器材マスタ（ご飯ジャー、カレージャー、ホテルパン等）
  - テプラ番号管理（例：ご飯ジャー1号、2号...）
  - 器材種別、サイズ、状態
- `equipment_inventories` - 器材在庫管理
  - 倉庫別在庫数、利用可能数
- `equipment_assignments` - 案件への器材割り当て
  - Order × Equipment の紐付け
- `drivers` - ドライバーマスタ
  - 配送会社との紐付け
  - 連絡先（LINE ID等）
- `delivery_routes` - 配送ルート管理
  - ルート最適化のための情報
