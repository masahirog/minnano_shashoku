require 'rails_helper'

RSpec.describe ConflictDetector do
  let(:company) { Company.create!(name: 'テスト企業', invoice_recipient: 'テスト企業') }
  let(:restaurant) do
    Restaurant.create!(
      name: 'テスト飲食店',
      contract_status: 'active',
      max_capacity: 100,
      capacity_per_day: 50,
      max_lots_per_day: 2,
      closed_days: ['sunday']
    )
  end
  let(:menu) { Menu.create!(name: 'テストメニュー', restaurant: restaurant) }

  describe '.detect_for_order' do
    it 'キャパシティオーバーを検出する' do
      # 既存案件（30食）
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: Date.today + 2.days,
        default_meal_count: 30,
        status: 'confirmed'
      )

      # 新規案件（25食） -> 合計55食でオーバー
      order = Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: Date.today + 2.days,
        default_meal_count: 25,
        status: 'pending'
      )

      conflicts = ConflictDetector.detect_for_order(order)
      capacity_conflict = conflicts.find { |c| c[:type] == :capacity_over }

      expect(capacity_conflict).not_to be_nil
      expect(capacity_conflict[:severity]).to eq(:high)
      expect(capacity_conflict[:details][:total_meal_count]).to eq(55)
    end

    it 'メニュー重複を検出する' do
      # 既存案件（月曜日）
      monday = Date.today.beginning_of_week(:monday)
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: monday,
        default_meal_count: 10,
        status: 'confirmed'
      )

      # 新規案件（水曜日、同じメニュー）
      wednesday = monday + 2.days
      order = Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday,
        default_meal_count: 10,
        status: 'pending'
      )

      conflicts = ConflictDetector.detect_for_order(order)
      menu_conflict = conflicts.find { |c| c[:type] == :menu_duplication }

      expect(menu_conflict).not_to be_nil
      expect(menu_conflict[:severity]).to eq(:medium)
    end

    it '時間帯重複を検出する' do
      # 既存案件（12:00回収）
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: Date.today + 2.days,
        default_meal_count: 10,
        status: 'confirmed',
        collection_time: Time.zone.parse('12:00')
      )

      # 新規案件（13:00回収） -> 2時間以内
      menu2 = Menu.create!(name: 'テストメニュー2', restaurant: restaurant)
      order = Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu2,
        order_type: 'trial',
        scheduled_date: Date.today + 2.days,
        default_meal_count: 10,
        status: 'pending',
        collection_time: Time.zone.parse('13:00')
      )

      conflicts = ConflictDetector.detect_for_order(order)
      time_conflicts = conflicts.select { |c| c[:type] == :time_overlap }

      expect(time_conflicts).not_to be_empty
      expect(time_conflicts.first[:severity]).to eq(:medium)
    end

    it '定休日を検出する' do
      # 日曜日（定休日）
      sunday = Date.today.beginning_of_week(:sunday)

      order = Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: sunday,
        default_meal_count: 10,
        status: 'pending'
      )

      conflicts = ConflictDetector.detect_for_order(order)
      closed_day_conflict = conflicts.find { |c| c[:type] == :closed_day }

      expect(closed_day_conflict).not_to be_nil
      expect(closed_day_conflict[:severity]).to eq(:high)
    end
  end

  describe '.detect_for_date' do
    it '指定日のすべてのコンフリクトを返す' do
      target_date = Date.today + 2.days

      # 案件1（30食）
      order1 = Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: target_date,
        default_meal_count: 30,
        status: 'confirmed'
      )

      # 案件2（25食） -> キャパシティオーバー
      order2 = Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: target_date,
        default_meal_count: 25,
        status: 'pending'
      )

      conflicts = ConflictDetector.detect_for_date(target_date)

      expect(conflicts).not_to be_empty
      expect(conflicts.length).to be >= 1
    end

    it 'キャンセルされた案件は含まれない' do
      target_date = Date.today + 2.days

      # キャンセルされた案件
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: target_date,
        default_meal_count: 30,
        status: 'cancelled',
        collection_time: Time.zone.parse('12:00')
      )

      conflicts = ConflictDetector.detect_for_date(target_date)

      expect(conflicts).to be_empty
    end
  end

  describe '.detect_for_range' do
    it '指定期間のすべてのコンフリクトを返す' do
      start_date = Date.today
      end_date = Date.today + 7.days

      # 複数の日付に案件を作成
      (start_date..end_date).each_with_index do |date, i|
        next if date.wday == 0 # 日曜日はスキップ

        Order.create!(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: date,
          default_meal_count: 30 + i * 5, # 徐々に増やしてキャパオーバーさせる
          status: 'confirmed'
        )
      end

      conflicts = ConflictDetector.detect_for_range(start_date, end_date)

      expect(conflicts).to be_a(Hash)
      # 少なくとも1日はコンフリクトがあるはず
      expect(conflicts.keys).not_to be_empty
    end
  end
end
