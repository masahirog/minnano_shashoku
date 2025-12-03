require 'rails_helper'

RSpec.describe "OrdersPerformance", type: :request do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') }
  let(:company) { Company.create!(name: 'テスト企業', invoice_recipient: 'テスト企業', color: '#2196f3') }
  let!(:restaurants) do
    5.times.map do |i|
      Restaurant.create!(
        name: "テスト飲食店#{i}",
        contract_status: 'active',
        max_capacity: 100,
        capacity_per_day: 50
      )
    end
  end
  let!(:menus) do
    restaurants.flat_map do |restaurant|
      3.times.map do |i|
        Menu.create!(name: "テストメニュー#{i}", restaurant: restaurant)
      end
    end
  end

  before do
    sign_in admin_user
  end

  describe "カレンダー表示のパフォーマンス" do
    before do
      # 30件の案件を作成
      30.times do |i|
        Order.create!(
          company: company,
          restaurant: restaurants.sample,
          menu: menus.sample,
          order_type: 'trial',
          scheduled_date: Date.today + (i % 30).days,
          default_meal_count: rand(10..50),
          status: 'confirmed',
          collection_time: Time.zone.parse("#{10 + (i % 8)}:00")
        )
      end
    end

    it "カレンダー表示で許容範囲のクエリ数で実行される" do
      # N+1クエリがないことを確認
      expect do
        get calendar_admin_orders_path
      end.to perform_under(50).queries
    end
  end

  describe "配送シート一覧のパフォーマンス" do
    before do
      # 50件の案件を作成
      50.times do |i|
        Order.create!(
          company: company,
          restaurant: restaurants.sample,
          menu: menus.sample,
          order_type: 'trial',
          scheduled_date: Date.today + (i % 7).days,
          default_meal_count: rand(10..50),
          status: 'confirmed',
          collection_time: Time.zone.parse("#{10 + (i % 8)}:00"),
          warehouse_pickup_time: Time.zone.parse("#{8 + (i % 8)}:00")
        )
      end
    end

    it "配送シート一覧で許容範囲のクエリ数で実行される" do
      expect do
        get delivery_sheets_admin_orders_path
      end.to perform_under(50).queries
    end
  end

  describe "スケジュール調整画面のパフォーマンス" do
    before do
      # 100件の案件を作成
      100.times do |i|
        Order.create!(
          company: company,
          restaurant: restaurants.sample,
          menu: menus.sample,
          order_type: 'trial',
          scheduled_date: Date.today + (i % 30).days,
          default_meal_count: rand(10..50),
          status: %w[pending confirmed completed].sample,
          collection_time: Time.zone.parse("#{10 + (i % 8)}:00")
        )
      end
    end

    it "スケジュール調整画面で許容範囲のクエリ数で実行される" do
      expect do
        get schedule_admin_orders_path
      end.to perform_under(50).queries
    end

    it "コンフリクト検出が効率的に実行される" do
      order = Order.first

      start_time = Time.current
      conflicts = order.schedule_conflicts
      end_time = Time.current

      # コンフリクト検出は100ms以内に完了すること
      expect(end_time - start_time).to be < 0.1
    end
  end

  describe "PDF生成のパフォーマンス" do
    before do
      # 20件の案件を作成
      20.times do |i|
        Order.create!(
          company: company,
          restaurant: restaurants.sample,
          menu: menus.sample,
          order_type: 'trial',
          scheduled_date: Date.today + (i % 7).days,
          default_meal_count: rand(10..50),
          status: 'confirmed',
          collection_time: Time.zone.parse("#{10 + (i % 8)}:00"),
          warehouse_pickup_time: Time.zone.parse("#{8 + (i % 8)}:00")
        )
      end
    end

    it "PDF生成が3秒以内に完了する" do
      orders = Order.where(scheduled_date: Date.today..(Date.today + 7.days))

      start_time = Time.current
      pdf = DeliverySheetPdfGenerator.new(orders, start_date: Date.today, end_date: Date.today + 7.days).generate
      end_time = Time.current

      expect(pdf).to be_present
      expect(end_time - start_time).to be < 3
    end
  end

  describe "ConflictDetectorのパフォーマンス" do
    before do
      # 50件の案件を作成
      50.times do |i|
        Order.create!(
          company: company,
          restaurant: restaurants.sample,
          menu: menus.sample,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: rand(10..30),
          status: 'confirmed',
          collection_time: Time.zone.parse("#{10 + (i % 8)}:00")
        )
      end
    end

    it "指定日のコンフリクト検出が効率的に実行される" do
      start_time = Time.current
      conflicts = ConflictDetector.detect_for_date(Date.today)
      end_time = Time.current

      # 50件の案件に対して1秒以内に完了すること
      expect(end_time - start_time).to be < 1
    end

    it "期間指定のコンフリクト検出が効率的に実行される" do
      start_time = Time.current
      conflicts = ConflictDetector.detect_for_range(Date.today, Date.today + 7.days)
      end_time = Time.current

      # 7日分の検出が3秒以内に完了すること
      expect(end_time - start_time).to be < 3
    end
  end
end

# カスタムマッチャー: クエリ数をチェック
RSpec::Matchers.define :perform_under do |expected|
  supports_block_expectations

  match do |block|
    query_count = 0

    ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      query_count += 1
    end

    block.call

    @actual = query_count
    @actual < expected
  end

  failure_message do |actual|
    "expected to perform under #{expected} queries, but performed #{@actual} queries"
  end
end
