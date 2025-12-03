require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:company) { Company.create!(name: 'テスト企業', formal_name: 'テスト企業株式会社', contract_status: 'active') }
  let(:restaurant) do
    Restaurant.create!(
      name: 'テスト飲食店',
      contract_status: 'active',
      max_capacity: 100,
      capacity_per_day: 50,
      max_lots_per_day: 2,
      closed_days: ['sunday', 'monday']
    )
  end
  let(:menu) { Menu.create!(name: 'テストメニュー', restaurant: restaurant) }

  describe 'バリデーション' do
    describe '#restaurant_capacity_check' do
      it '1日の合計食数がキャパシティを超える場合、エラーになる' do
        # 既存の案件を作成（30食）
        Order.create!(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: 30,
          status: 'confirmed'
        )

        # 新しい案件（25食）を作成 -> 合計55食でキャパシティ（50食）を超える
        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: 25,
          status: 'pending'
        )

        expect(order).not_to be_valid
        expect(order.errors[:default_meal_count]).to include(match(/キャパシティ/))
      end

      it '1日の案件数が最大ロット数を超える場合、エラーになる' do
        # 既存の案件を2件作成
        2.times do |i|
          Order.create!(
            company: company,
            restaurant: restaurant,
            menu: menu,
            order_type: 'trial',
            scheduled_date: Date.today,
            default_meal_count: 10,
            status: 'confirmed'
          )
        end

        # 3件目を作成 -> max_lots_per_day（2件）を超える
        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: 10,
          status: 'pending'
        )

        expect(order).not_to be_valid
        expect(order.errors[:scheduled_date]).to include(match(/最大ロット数/))
      end

      it 'キャンセルされた案件はキャパシティ計算に含まれない' do
        # キャンセルされた案件（30食）
        Order.create!(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: 30,
          status: 'cancelled'
        )

        # 新しい案件（40食）-> キャンセル案件は含まれないので有効
        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: 40,
          status: 'pending'
        )

        expect(order).to be_valid
      end
    end

    describe '#restaurant_not_closed' do
      it '定休日の場合、エラーになる' do
        # 日曜日（closed_daysに含まれる）
        sunday = Date.today.beginning_of_week(:sunday) # 日曜日

        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: sunday,
          default_meal_count: 10,
          status: 'pending'
        )

        expect(order).not_to be_valid
        expect(order.errors[:scheduled_date]).to include(match(/定休日/))
      end

      it '定休日でない場合、有効' do
        # 水曜日（closed_daysに含まれない）
        wednesday = Date.today.beginning_of_week(:monday) + 2.days

        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: wednesday,
          default_meal_count: 10,
          status: 'pending'
        )

        expect(order).to be_valid
      end
    end

    describe '#delivery_time_feasible' do
      it '倉庫集荷時刻が回収時刻よりも後の場合、エラーになる' do
        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: 10,
          status: 'pending',
          warehouse_pickup_time: Time.zone.parse('12:00'),
          collection_time: Time.zone.parse('11:00')
        )

        expect(order).not_to be_valid
        expect(order.errors[:warehouse_pickup_time]).to include(match(/前である必要/))
      end

      it '倉庫集荷から回収まで30分未満の場合、エラーになる' do
        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today,
          default_meal_count: 10,
          status: 'pending',
          warehouse_pickup_time: Time.zone.parse('11:40'),
          collection_time: Time.zone.parse('12:00')
        )

        expect(order).not_to be_valid
        expect(order.errors[:collection_time]).to include(match(/30分の余裕/))
      end

      it '倉庫集荷から回収まで30分以上ある場合、有効' do
        order = Order.new(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: Date.today + 1.day, # 定休日を避ける
          default_meal_count: 10,
          status: 'pending',
          warehouse_pickup_time: Time.zone.parse('11:00'),
          collection_time: Time.zone.parse('12:00')
        )

        expect(order).to be_valid
      end
    end
  end

  describe '#duplicate_menu_in_week?' do
    it '同じ週に同じメニューがある場合、trueを返す' do
      # 水曜日に案件作成（月曜は定休日のため）
      monday = Date.today.beginning_of_week(:monday)
      wednesday = monday + 2.days
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday,
        default_meal_count: 10,
        status: 'confirmed'
      )

      # 金曜日に同じメニュー
      friday = monday + 4.days
      order = Order.new(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: friday,
        default_meal_count: 10,
        status: 'pending'
      )

      expect(order.duplicate_menu_in_week?).to be true
    end

    it '同じ週に同じメニューがない場合、falseを返す' do
      # 先週の水曜日に案件作成（月曜は定休日のため）
      last_week_monday = Date.today.beginning_of_week(:monday) - 7.days
      last_week_wednesday = last_week_monday + 2.days
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: last_week_wednesday,
        default_meal_count: 10,
        status: 'confirmed'
      )

      # 今週の水曜日
      wednesday = Date.today.beginning_of_week(:monday) + 2.days
      order = Order.new(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday,
        default_meal_count: 10,
        status: 'pending'
      )

      expect(order.duplicate_menu_in_week?).to be false
    end
  end

  describe '#schedule_conflicts' do
    it '時間帯が重複する案件がある場合、コンフリクトを返す' do
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

      # 新規案件（12:30回収） -> 2時間以内なのでコンフリクト
      order = Order.new(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: Date.today + 2.days,
        default_meal_count: 10,
        status: 'pending',
        collection_time: Time.zone.parse('12:30')
      )

      conflicts = order.schedule_conflicts
      expect(conflicts).not_to be_empty
      expect(conflicts.first[:type]).to eq(:restaurant_time_overlap)
    end

    it '同じ企業の同じ日に複数配送がある場合、コンフリクトを返す' do
      # 既存案件
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: Date.today + 2.days,
        default_meal_count: 10,
        status: 'confirmed'
      )

      # 新規案件（同じ企業、同じ日）
      menu2 = Menu.create!(name: 'テストメニュー2', restaurant: restaurant)
      restaurant2 = Restaurant.create!(
        name: 'テスト飲食店2',
        contract_status: 'active',
        max_capacity: 100,
        capacity_per_day: 50
      )

      order = Order.new(
        company: company,
        restaurant: restaurant2,
        menu: menu2,
        order_type: 'trial',
        scheduled_date: Date.today + 2.days,
        default_meal_count: 10,
        status: 'pending'
      )

      conflicts = order.schedule_conflicts
      expect(conflicts).not_to be_empty
      expect(conflicts.first[:type]).to eq(:multiple_deliveries_same_day)
    end
  end
end
