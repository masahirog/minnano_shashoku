# Phase 1 実装計画：スケジュール管理MVP

## 期間

4週間（実装3週間 + テスト・調整1週間）

## 目標

スプレッドシートで行っている「案件マスター」「配送予定スケジュール」の管理をシステム化し、配送シートを自動生成できるようにする。

## 完了条件

- [ ] 定期スケジュールを登録でき、自動的にOrderが生成される
- [ ] 週間・月間カレンダーで案件を一覧できる
- [ ] メニュー重複がアラート表示される
- [ ] 配送シートをPDF/Excelで出力できる
- [ ] 飲食店のキャパ・定休日をチェックできる
- [ ] 1週間の実運用テストで問題なし

---

## Week 1: RecurringOrderモデル + 自動生成

### Day 1-2: データベース設計・マイグレーション

**タスク:**
1. マイグレーションファイル作成
2. RecurringOrderモデル作成
3. 既存モデル（Order, Restaurant, Company）への追加フィールド
4. マイグレーション実行

**成果物:**
```
db/migrate/
├── 20250102_create_recurring_orders.rb
├── 20250102_add_schedule_fields_to_orders.rb
├── 20250102_add_delivery_flow_fields_to_orders.rb  # 配送フロー関連カラム追加
├── 20250102_add_capacity_fields_to_restaurants.rb
└── 20250102_add_delivery_fields_to_companies.rb

app/models/recurring_order.rb
```

**配送フロー関連の追加カラム（業務マニュアルに基づく）:**
- `is_trial`: 試食会/本導入の区別
- `collection_time`: 器材回収時刻
- `warehouse_pickup_time`: 倉庫集荷時刻
- `return_location`: 器材返却先
- `equipment_notes`: 器材メモ（Phase 1簡易対応）

**確認項目:**
- [ ] マイグレーションが正常に実行できる
- [ ] ロールバックも問題なく動作する
- [ ] インデックスが適切に設定されている

### Day 3-4: RecurringOrderモデルの実装

**タスク:**
1. バリデーション実装
2. アソシエーション設定
3. スコープ定義（active, for_day_of_week等）
4. モデルテスト作成

**実装内容:**
```ruby
# app/models/recurring_order.rb
class RecurringOrder < ApplicationRecord
  belongs_to :company
  belongs_to :restaurant
  belongs_to :menu, optional: true
  belongs_to :delivery_company, optional: true
  has_many :orders, dependent: :nullify

  validates :day_of_week, inclusion: { in: 0..6 }
  validates :frequency, inclusion: { in: %w[weekly biweekly monthly] }
  validates :default_meal_count, numericality: { only_integer: true, greater_than: 0 }
  validates :delivery_time, :start_date, presence: true
  validate :end_date_after_start_date
  validate :restaurant_capacity_check
  validate :restaurant_not_closed_on_day

  scope :active, -> { where(is_active: true, status: 'active') }
  scope :for_day_of_week, ->(day) { where(day_of_week: day) }
  scope :current, -> { where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.today, Date.today) }

  def generate_orders_for_range(start_date, end_date)
    # 実装はDay 5-6
  end
end
```

**確認項目:**
- [ ] バリデーションが正しく動作する
- [ ] テストがすべてパスする

### Day 5-6: Order自動生成機能

**タスク:**
1. `RecurringOrder#generate_orders_for_range` 実装
2. Rakeタスク作成（手動実行用）
3. バックグラウンドジョブ作成（Sidekiq）
4. テスト作成

**実装内容:**
```ruby
# app/services/recurring_order_generator.rb
class RecurringOrderGenerator
  def self.generate_for_period(start_date, end_date)
    RecurringOrder.active.current.find_each do |recurring_order|
      recurring_order.generate_orders_for_range(start_date, end_date)
    end
  end
end

# lib/tasks/orders.rake
namespace :orders do
  desc "Generate orders from recurring schedules for next N weeks"
  task :generate, [:weeks] => :environment do |t, args|
    weeks = args[:weeks]&.to_i || 4
    start_date = Date.today
    end_date = start_date + weeks.weeks

    puts "Generating orders from #{start_date} to #{end_date}..."
    RecurringOrderGenerator.generate_for_period(start_date, end_date)
    puts "Done!"
  end
end

# app/jobs/generate_orders_job.rb
class GenerateOrdersJob < ApplicationJob
  queue_as :default

  def perform(weeks = 4)
    start_date = Date.today
    end_date = start_date + weeks.weeks
    RecurringOrderGenerator.generate_for_period(start_date, end_date)
  end
end
```

**確認項目:**
- [ ] 定期スケジュールから正しくOrderが生成される
- [ ] weekly/biweekly/monthlyの頻度が正しく処理される
- [ ] 既存Orderと重複しない
- [ ] Rakeタスクが動作する

### Day 7: 管理画面実装（RecurringOrder）

**タスク:**
1. RecurringOrderのDashboard作成
2. CRUD画面のカスタマイズ
3. 一括生成ボタンの追加

**実装内容:**
```ruby
# app/dashboards/recurring_order_dashboard.rb
# app/controllers/admin/recurring_orders_controller.rb
# app/views/admin/recurring_orders/_form.html.erb
```

**確認項目:**
- [ ] 新規登録・編集・削除ができる
- [ ] 一覧で必要な情報が見える
- [ ] 一括生成ボタンが動作する

---

## Week 2: カレンダービュー

### Day 8-9: カレンダー表示の基本実装

**タスク:**
1. Gemインストール（simple_calendar）
2. 週間カレンダービュー作成
3. 月間カレンダービュー作成
4. OrdersControllerにカレンダーアクション追加

**実装内容:**
```ruby
# Gemfile
gem 'simple_calendar'

# app/controllers/admin/orders_controller.rb
def calendar
  @orders = Order.where(delivery_date: params[:start_date]..params[:end_date])
                 .includes(:company, :restaurant, :menu)
                 .order(:delivery_date, :delivery_time)
end

# app/views/admin/orders/calendar.html.erb
```

**確認項目:**
- [ ] 週間ビューで案件が表示される
- [ ] 月間ビューで案件が表示される
- [ ] 前後の週・月への移動ができる

### Day 10-11: カレンダーUIの改善

**タスク:**
1. 企業別・飲食店別の色分け
2. ツールチップ表示（詳細情報）
3. ドラッグ&ドロップでの日付変更（オプション）
4. フィルター機能（企業・飲食店・ステータス）

**実装内容:**
```erb
<!-- app/views/admin/orders/calendar.html.erb -->
<div class="calendar-filters">
  <%= form_tag admin_orders_calendar_path, method: :get do %>
    <%= select_tag :company_id, options_from_collection_for_select(Company.all, :id, :name, params[:company_id]), include_blank: "全企業" %>
    <%= select_tag :restaurant_id, options_from_collection_for_select(Restaurant.all, :id, :name, params[:restaurant_id]), include_blank: "全飲食店" %>
    <%= submit_tag "絞り込み", class: "btn btn-primary btn-sm" %>
  <% end %>
</div>

<%= month_calendar(events: @orders, attribute: :delivery_date) do |date, orders| %>
  <%= date.day %>
  <% orders.each do |order| %>
    <div class="calendar-event" style="background-color: <%= order.company.color %>">
      <%= link_to "#{order.company.name} - #{order.restaurant.name}", admin_order_path(order) %>
    </div>
  <% end %>
<% end %>
```

**確認項目:**
- [ ] 企業別に色分けされている
- [ ] ホバーで詳細が表示される
- [ ] フィルターが動作する

### Day 12: メニュー重複チェック機能

**タスク:**
1. 重複検出ロジック実装
2. アラート表示機能
3. Orderモデルにバリデーション追加

**実装内容:**
```ruby
# app/models/order.rb
validate :menu_duplication_warning

def menu_duplication_warning
  return unless menu_id && company_id && delivery_date

  week_start = delivery_date.beginning_of_week
  week_end = delivery_date.end_of_week

  duplicate = Order.where(company_id: company_id, menu_id: menu_id)
                   .where(delivery_date: week_start..week_end)
                   .where.not(id: id)
                   .exists?

  if duplicate
    errors.add(:menu_id, "この週に同じメニューが既に予定されています")
  end
end

# app/services/menu_duplication_checker.rb
class MenuDuplicationChecker
  def self.check_for_week(date)
    week_start = date.beginning_of_week
    week_end = date.end_of_week

    duplicates = Order.where(delivery_date: week_start..week_end)
                      .group(:company_id, :menu_id)
                      .having('COUNT(*) > 1')
                      .count

    duplicates.map do |(company_id, menu_id), count|
      {
        company: Company.find(company_id),
        menu: Menu.find(menu_id),
        count: count
      }
    end
  end
end
```

**確認項目:**
- [ ] 同じ企業に同じ週に同じメニューが2回以上あるとアラート
- [ ] カレンダー画面でアラート表示
- [ ] 登録時にも警告が出る

### Day 13-14: スケジュール調整画面

**タスク:**
1. ドラッグ&ドロップでの案件移動
2. 一括編集機能
3. コンフリクト表示

**実装内容:**
```javascript
// app/javascript/admin/calendar.js
// ドラッグ&ドロップ実装（Stimulus）
```

**確認項目:**
- [ ] 案件をドラッグして日付変更できる
- [ ] 複数案件を選択して一括編集できる
- [ ] コンフリクトが視覚的に表示される

---

## Week 3: 配送シート生成

### Day 15-16: 配送シートPDF生成（Prawn）

**タスク:**
1. Prawn gemインストール・設定
2. 配送シートテンプレート作成
3. PDF生成サービス実装
4. ダウンロード機能追加

**実装内容:**
```ruby
# Gemfile
gem 'prawn'
gem 'prawn-table'

# app/services/delivery_sheet_pdf_generator.rb
class DeliverySheetPdfGenerator
  def initialize(orders)
    @orders = orders.includes(:company, :restaurant, :menu, :delivery_company)
  end

  def generate
    Prawn::Document.new(page_size: 'A4', page_layout: :landscape) do |pdf|
      pdf.font "#{Rails.root}/app/assets/fonts/NotoSansJP-Regular.ttf"

      @orders.group_by(&:delivery_date).each do |date, daily_orders|
        generate_daily_sheet(pdf, date, daily_orders)
        pdf.start_new_page unless date == @orders.last.delivery_date
      end
    end
  end

  private

  def generate_daily_sheet(pdf, date, orders)
    pdf.text "配送シート - #{date.strftime('%Y年%m月%d日 (%a)')}", size: 16, style: :bold
    pdf.move_down 10

    table_data = [
      ['倉庫集荷', '飲食店集荷', '納品時間', '企業名', '住所', '食数', '飲食店', 'メニュー', '回収時間', '返却先', '器材', '試食/本導入', 'ドライバー']
    ]

    orders.sort_by(&:delivery_time).each do |order|
      table_data << [
        order.warehouse_pickup_time&.strftime('%H:%M') || '-',
        order.pickup_time&.strftime('%H:%M') || '-',
        order.delivery_time.strftime('%H:%M'),
        order.company.name,
        order.company.address,
        "#{order.meal_count}食",
        order.restaurant.name,
        order.menu&.name || '未定',
        order.collection_time&.strftime('%H:%M') || '-',
        order.return_location == 'warehouse' ? '倉庫' : '飲食店',
        order.equipment_notes || '-',
        order.is_trial ? '試食会' : '本導入',
        order.driver&.name || '未割当'
      ]
    end

    pdf.table(table_data, header: true, width: pdf.bounds.width) do
      row(0).font_style = :bold
      cells.padding = 6
      cells.borders = [:top, :bottom]
      cells.size = 8  # フォントサイズを小さくして収まるように
    end
  end
end

# app/controllers/admin/orders_controller.rb
def delivery_sheet_pdf
  @orders = Order.where(id: params[:order_ids])
  pdf = DeliverySheetPdfGenerator.new(@orders).generate

  send_data pdf.render,
            filename: "delivery_sheet_#{Date.today.strftime('%Y%m%d')}.pdf",
            type: 'application/pdf',
            disposition: 'inline'
end
```

**確認項目:**
- [ ] PDFが生成される
- [ ] 日本語フォントが表示される
- [ ] レイアウトが見やすい
- [ ] 複数日分をまとめて出力できる

### Day 17-18: 配送シートExcel生成（Caxlsx）

**タスク:**
1. Caxlsx gemインストール
2. Excelテンプレート作成
3. Excel生成サービス実装
4. ダウンロード機能追加

**実装内容:**
```ruby
# Gemfile
gem 'caxlsx'
gem 'caxlsx_rails'

# app/services/delivery_sheet_excel_generator.rb
class DeliverySheetExcelGenerator
  def initialize(orders)
    @orders = orders.includes(:company, :restaurant, :menu, :delivery_company)
  end

  def generate
    package = Axlsx::Package.new
    workbook = package.workbook

    @orders.group_by(&:delivery_date).each do |date, daily_orders|
      generate_daily_sheet(workbook, date, daily_orders)
    end

    package.to_stream
  end

  private

  def generate_daily_sheet(workbook, date, orders)
    workbook.add_worksheet(name: date.strftime('%m/%d')) do |sheet|
      sheet.add_row ["配送シート - #{date.strftime('%Y年%m月%d日 (%a)')}"], style: workbook.styles.add_style(sz: 14, b: true)
      sheet.add_row []
      sheet.add_row ['倉庫集荷', '飲食店集荷', '納品時間', '企業名', '住所', '食数', '飲食店', 'メニュー', '回収時間', '返却先', '器材', '試食/本導入', 'ドライバー']

      orders.sort_by(&:delivery_time).each do |order|
        sheet.add_row [
          order.warehouse_pickup_time&.strftime('%H:%M') || '-',
          order.pickup_time&.strftime('%H:%M') || '-',
          order.delivery_time.strftime('%H:%M'),
          order.company.name,
          order.company.address,
          order.meal_count,
          order.restaurant.name,
          order.menu&.name || '未定',
          order.collection_time&.strftime('%H:%M') || '-',
          order.return_location == 'warehouse' ? '倉庫' : '飲食店',
          order.equipment_notes || '-',
          order.is_trial ? '試食会' : '本導入',
          order.driver&.name || '未割当'
        ]
      end
    end
  end
end

# app/controllers/admin/orders_controller.rb
def delivery_sheet_excel
  @orders = Order.where(id: params[:order_ids])
  xlsx = DeliverySheetExcelGenerator.new(@orders).generate

  send_data xlsx.read,
            filename: "delivery_sheet_#{Date.today.strftime('%Y%m%d')}.xlsx",
            type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
end
```

**確認項目:**
- [ ] Excelファイルが生成される
- [ ] 日付ごとにシートが分かれている
- [ ] セルの書式が適切
- [ ] Excelで開いて編集できる

### Day 19-20: 配送シート画面の実装

**タスク:**
1. 配送シート一覧画面
2. 日付・配送会社別のフィルター
3. 一括出力機能
4. 個別出力機能

**実装内容:**
```erb
<!-- app/views/admin/orders/delivery_sheets.html.erb -->
<div class="card">
  <div class="card-header">
    <h3>配送シート出力</h3>
  </div>

  <div class="card-body">
    <%= form_tag admin_orders_delivery_sheets_path, method: :get do %>
      <%= date_field_tag :start_date, params[:start_date] || Date.today %>
      <%= date_field_tag :end_date, params[:end_date] || 1.week.from_now %>
      <%= select_tag :delivery_company_id, options_from_collection_for_select(DeliveryCompany.all, :id, :name, params[:delivery_company_id]), include_blank: "全配送会社" %>
      <%= submit_tag "表示", class: "btn btn-primary btn-sm" %>
    <% end %>

    <% if @orders.any? %>
      <div class="mt-3">
        <%= link_to "PDF出力", delivery_sheet_pdf_admin_orders_path(order_ids: @orders.pluck(:id), format: :pdf), class: "btn btn-success btn-sm", target: "_blank" %>
        <%= link_to "Excel出力", delivery_sheet_excel_admin_orders_path(order_ids: @orders.pluck(:id), format: :xlsx), class: "btn btn-info btn-sm" %>
      </div>

      <table class="table table-striped mt-3">
        <!-- 配送シートのプレビュー -->
      </table>
    <% end %>
  </div>
</div>
```

**確認項目:**
- [ ] 日付範囲で絞り込める
- [ ] 配送会社で絞り込める
- [ ] PDF/Excel両方出力できる
- [ ] プレビュー表示が見やすい

### Day 21: 日本語フォント設定

**タスク:**
1. Noto Sans JPフォントダウンロード
2. フォント配置
3. PDF生成時のフォント適用

**実装内容:**
```bash
# フォントダウンロード
mkdir -p app/assets/fonts
cd app/assets/fonts
wget https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/Japanese/NotoSansJP-Regular.otf
```

```ruby
# config/initializers/prawn.rb
Prawn::Font::AFM.hide_m17n_warning = true
```

**確認項目:**
- [ ] PDFで日本語が正しく表示される
- [ ] 文字化けがない

---

## Week 4: 制約チェック + テスト

### Day 22-23: バリデーション・制約チェック強化

**タスク:**
1. 飲食店キャパチェック
2. 定休日チェック
3. 配送時間制約チェック
4. コンフリクト検出

**実装内容:**
```ruby
# app/models/order.rb
validate :restaurant_capacity_check
validate :restaurant_not_closed
validate :delivery_time_feasible

def restaurant_capacity_check
  return unless restaurant && delivery_date && meal_count

  daily_total = Order.where(restaurant_id: restaurant_id, delivery_date: delivery_date)
                     .where.not(id: id)
                     .sum(:meal_count) + meal_count

  if daily_total > restaurant.capacity_per_day
    errors.add(:meal_count, "飲食店の1日のキャパ（#{restaurant.capacity_per_day}食）を超えています")
  end
end

def restaurant_not_closed
  return unless restaurant && delivery_date

  day_of_week = delivery_date.wday
  if restaurant.regular_holiday&.split(',')&.map(&:to_i)&.include?(day_of_week)
    errors.add(:delivery_date, "飲食店の定休日です")
  end
end

def delivery_time_feasible
  return unless restaurant && pickup_time && delivery_time && company

  travel_time = calculate_travel_time(restaurant.address, company.address)
  required_time = pickup_time + travel_time.minutes + 30.minutes  # 設置時間30分

  if required_time > delivery_time
    errors.add(:delivery_time, "集荷→納品の時間が足りません（最低#{required_time.strftime('%H:%M')}必要）")
  end
end

# app/services/conflict_detector.rb
class ConflictDetector
  def self.detect_for_date(date)
    conflicts = []

    # 1. 飲食店キャパオーバー
    Restaurant.find_each do |restaurant|
      orders = Order.where(restaurant_id: restaurant.id, delivery_date: date)
      total = orders.sum(:meal_count)

      if total > restaurant.capacity_per_day
        conflicts << {
          type: 'capacity_over',
          restaurant: restaurant,
          total: total,
          capacity: restaurant.capacity_per_day,
          orders: orders
        }
      end
    end

    # 2. ドライバー重複
    # 3. メニュー重複

    conflicts
  end
end
```

**確認項目:**
- [ ] キャパオーバーが検出される
- [ ] 定休日登録が防止される
- [ ] 配送時間の矛盾が検出される

### Day 24-25: 統合テスト・調整

**タスク:**
1. E2Eテスト作成（RSpec/Capybara）
2. パフォーマンステスト
3. バグ修正
4. ドキュメント更新

**テストシナリオ:**
```ruby
# spec/features/recurring_orders_spec.rb
describe '定期スケジュール管理', type: :feature do
  it '定期スケジュールを登録すると自動的にOrderが生成される' do
    # テストシナリオ
  end

  it 'メニュー重複時にアラートが表示される' do
    # テストシナリオ
  end

  it '配送シートPDFが正しく生成される' do
    # テストシナリオ
  end
end
```

**確認項目:**
- [ ] すべてのテストがパスする
- [ ] パフォーマンスに問題がない
- [ ] UIが使いやすい

### Day 26-28: 実運用テスト・スプシ廃止準備

**タスク:**
1. 本番環境デプロイ
2. 実データ移行
3. 1週間の実運用テスト
4. スプレッドシート廃止判断

**チェックリスト:**
- [ ] 既存スプシのデータを全て移行完了
- [ ] 1週間の運用で致命的なバグなし
- [ ] 配送シート出力が実用レベル
- [ ] 操作マニュアル作成完了
- [ ] ロールバック手順確認完了

**スプシ廃止の判断基準:**
- すべてのチェックリストが✅
- 実運用で問題なく1週間回せた
- 戻せる準備ができている

---

## 成果物まとめ

### コード
- `app/models/recurring_order.rb`
- `app/services/recurring_order_generator.rb`
- `app/services/delivery_sheet_pdf_generator.rb`
- `app/services/delivery_sheet_excel_generator.rb`
- `app/services/menu_duplication_checker.rb`
- `app/services/conflict_detector.rb`
- `app/jobs/generate_orders_job.rb`
- カレンダービュー関連（Controller/View）
- 配送シート関連（Controller/View）

### ドキュメント
- 操作マニュアル
- データ移行手順書
- ロールバック手順書

### テスト
- Model spec
- Feature spec (E2E)

---

## リスクと対策

| リスク | 対策 |
|--------|------|
| PDF生成が遅い | 非同期ジョブ化、キャッシュ活用 |
| カレンダーが重い | ページング、lazy load |
| データ移行ミス | 移行前バックアップ、検証スクリプト |
| 使い勝手が悪い | 早めにプロトタイプ確認、フィードバック反映 |

---

## 次のステップ（Phase 2）

Phase 1完了後、請求・支払い管理に進みます。
