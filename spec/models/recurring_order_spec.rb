require 'rails_helper'

RSpec.describe RecurringOrder, type: :model do
  describe 'associations' do
    it 'belongs to company' do
      expect(described_class.reflect_on_association(:company).macro).to eq(:belongs_to)
    end

    it 'belongs to restaurant' do
      expect(described_class.reflect_on_association(:restaurant).macro).to eq(:belongs_to)
    end

    it 'belongs to menu (optional)' do
      expect(described_class.reflect_on_association(:menu).macro).to eq(:belongs_to)
    end

    it 'belongs to delivery_company (optional)' do
      expect(described_class.reflect_on_association(:delivery_company).macro).to eq(:belongs_to)
    end

    it 'has many orders' do
      expect(described_class.reflect_on_association(:orders).macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    context 'basic validations' do
      it 'is valid with valid attributes' do
        recurring_order = build(:recurring_order)
        expect(recurring_order).to be_valid
      end

      it 'is invalid without a company' do
        recurring_order = build(:recurring_order, company: nil)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:company]).to be_present
      end

      it 'is invalid without a restaurant' do
        recurring_order = build(:recurring_order, restaurant: nil)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:restaurant]).to be_present
      end

      it 'is invalid without a delivery_time' do
        recurring_order = build(:recurring_order, delivery_time: nil)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:delivery_time]).to be_present
      end

      it 'is invalid without a start_date' do
        recurring_order = build(:recurring_order, start_date: nil)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:start_date]).to be_present
      end
    end

    context 'day_of_week validation' do
      it 'is valid with day_of_week 0-6' do
        (0..6).each do |day|
          recurring_order = build(:recurring_order, day_of_week: day)
          expect(recurring_order).to be_valid
        end
      end

      it 'is invalid with day_of_week outside 0-6' do
        recurring_order = build(:recurring_order, day_of_week: 7)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:day_of_week]).to be_present
      end

      it 'is invalid with negative day_of_week' do
        recurring_order = build(:recurring_order, day_of_week: -1)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:day_of_week]).to be_present
      end
    end

    context 'frequency validation' do
      it 'is valid with frequency weekly' do
        recurring_order = build(:recurring_order, frequency: 'weekly')
        expect(recurring_order).to be_valid
      end

      it 'is valid with frequency biweekly' do
        recurring_order = build(:recurring_order, frequency: 'biweekly')
        expect(recurring_order).to be_valid
      end

      it 'is valid with frequency monthly' do
        recurring_order = build(:recurring_order, frequency: 'monthly')
        expect(recurring_order).to be_valid
      end

      it 'is invalid with invalid frequency' do
        recurring_order = build(:recurring_order, frequency: 'daily')
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:frequency]).to be_present
      end
    end

    context 'default_meal_count validation' do
      it 'is valid with positive meal count' do
        recurring_order = build(:recurring_order, default_meal_count: 50)
        expect(recurring_order).to be_valid
      end

      it 'is invalid with zero meal count' do
        recurring_order = build(:recurring_order, default_meal_count: 0)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:default_meal_count]).to be_present
      end

      it 'is invalid with negative meal count' do
        recurring_order = build(:recurring_order, default_meal_count: -10)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:default_meal_count]).to be_present
      end
    end

    context 'end_date_after_start_date validation' do
      it 'is valid when end_date is after start_date' do
        recurring_order = build(:recurring_order, start_date: Date.today, end_date: Date.today + 30)
        expect(recurring_order).to be_valid
      end

      it 'is valid when end_date is nil' do
        recurring_order = build(:recurring_order, start_date: Date.today, end_date: nil)
        expect(recurring_order).to be_valid
      end

      it 'is invalid when end_date is before start_date' do
        recurring_order = build(:recurring_order, start_date: Date.today, end_date: Date.today - 1)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:end_date]).to include('は開始日より後の日付を指定してください')
      end
    end

    context 'restaurant_capacity_check validation' do
      it 'is valid when meal count is within restaurant capacity' do
        restaurant = create(:restaurant, capacity_per_day: 100)
        recurring_order = build(:recurring_order, restaurant: restaurant, default_meal_count: 50)
        expect(recurring_order).to be_valid
      end

      it 'is invalid when meal count exceeds restaurant capacity' do
        restaurant = create(:restaurant, capacity_per_day: 100)
        recurring_order = build(:recurring_order, restaurant: restaurant, default_meal_count: 150)
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:default_meal_count]).to include('が飲食店の1日のキャパ（100食）を超えています')
      end

      it 'is valid when restaurant has no capacity_per_day set' do
        restaurant = create(:restaurant, capacity_per_day: nil)
        recurring_order = build(:recurring_order, restaurant: restaurant, default_meal_count: 500)
        expect(recurring_order).to be_valid
      end
    end

    context 'restaurant_not_closed_on_day validation' do
      it 'is valid when day_of_week is not a regular holiday' do
        restaurant = create(:restaurant, regular_holiday: '0,6') # 日曜・土曜
        recurring_order = build(:recurring_order, restaurant: restaurant, day_of_week: 1) # 月曜
        expect(recurring_order).to be_valid
      end

      it 'is invalid when day_of_week is a regular holiday' do
        restaurant = create(:restaurant, regular_holiday: '0,6') # 日曜・土曜
        recurring_order = build(:recurring_order, restaurant: restaurant, day_of_week: 0) # 日曜
        expect(recurring_order).not_to be_valid
        expect(recurring_order.errors[:day_of_week]).to include('は飲食店の定休日です')
      end

      it 'is valid when restaurant has no regular_holiday set' do
        restaurant = create(:restaurant, regular_holiday: nil)
        recurring_order = build(:recurring_order, restaurant: restaurant, day_of_week: 0)
        expect(recurring_order).to be_valid
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active recurring orders' do
        active1 = create(:recurring_order, is_active: true, status: 'active')
        active2 = create(:recurring_order, is_active: true, status: 'active')
        inactive1 = create(:recurring_order, is_active: false, status: 'active')
        inactive2 = create(:recurring_order, is_active: true, status: 'paused')

        expect(RecurringOrder.active).to include(active1, active2)
        expect(RecurringOrder.active).not_to include(inactive1, inactive2)
      end
    end

    describe '.for_day_of_week' do
      it 'returns recurring orders for specified day' do
        monday = create(:recurring_order, day_of_week: 1)
        tuesday = create(:recurring_order, day_of_week: 2)
        wednesday = create(:recurring_order, day_of_week: 3)

        expect(RecurringOrder.for_day_of_week(1)).to include(monday)
        expect(RecurringOrder.for_day_of_week(1)).not_to include(tuesday, wednesday)
      end
    end

    describe '.current' do
      it 'returns recurring orders that are currently valid' do
        past = create(:recurring_order, start_date: Date.today - 60, end_date: Date.today - 30)
        current_with_end = create(:recurring_order, start_date: Date.today - 30, end_date: Date.today + 30)
        current_without_end = create(:recurring_order, start_date: Date.today - 30, end_date: nil)
        future = create(:recurring_order, start_date: Date.today + 30, end_date: Date.today + 60)

        current_orders = RecurringOrder.current
        expect(current_orders).to include(current_with_end, current_without_end)
        expect(current_orders).not_to include(past, future)
      end
    end
  end

  describe '#generate_orders_for_range' do
    let(:recurring_order) do
      create(:recurring_order,
        day_of_week: 1, # Monday
        frequency: 'weekly',
        start_date: Date.new(2025, 1, 6), # Monday, Jan 6, 2025
        end_date: nil
      )
    end

    it 'generates orders for matching days of week' do
      start_date = Date.new(2025, 1, 6)  # Monday
      end_date = Date.new(2025, 1, 27)   # 3 weeks later

      orders = recurring_order.generate_orders_for_range(start_date, end_date)

      expect(orders.size).to eq(4) # 4 Mondays in this range
      expect(orders.map(&:scheduled_date)).to match_array([
        Date.new(2025, 1, 6),
        Date.new(2025, 1, 13),
        Date.new(2025, 1, 20),
        Date.new(2025, 1, 27)
      ])
    end

    it 'does not generate orders for non-matching days' do
      start_date = Date.new(2025, 1, 7)  # Tuesday
      end_date = Date.new(2025, 1, 8)    # Wednesday

      orders = recurring_order.generate_orders_for_range(start_date, end_date)

      expect(orders).to be_empty
    end

    it 'respects the start_date boundary' do
      start_date = Date.new(2025, 1, 13) # Second Monday
      end_date = Date.new(2025, 1, 27)

      orders = recurring_order.generate_orders_for_range(start_date, end_date)

      expect(orders.size).to eq(3)
      expect(orders.map(&:scheduled_date)).to match_array([
        Date.new(2025, 1, 13),
        Date.new(2025, 1, 20),
        Date.new(2025, 1, 27)
      ])
    end

    it 'respects the end_date boundary when set' do
      recurring_order.update(end_date: Date.new(2025, 1, 20))

      start_date = Date.new(2025, 1, 6)
      end_date = Date.new(2025, 1, 27)

      orders = recurring_order.generate_orders_for_range(start_date, end_date)

      expect(orders.size).to eq(3)
      expect(orders.map(&:scheduled_date)).to match_array([
        Date.new(2025, 1, 6),
        Date.new(2025, 1, 13),
        Date.new(2025, 1, 20)
      ])
    end

    it 'does not create duplicate orders' do
      start_date = Date.new(2025, 1, 6)
      end_date = Date.new(2025, 1, 13)

      # First generation
      first_orders = recurring_order.generate_orders_for_range(start_date, end_date)
      expect(first_orders.size).to eq(2)

      # Second generation (should not create duplicates)
      second_orders = recurring_order.generate_orders_for_range(start_date, end_date)
      expect(second_orders.size).to eq(0)

      # Total orders in database
      total_orders = Order.where(recurring_order_id: recurring_order.id).count
      expect(total_orders).to eq(2)
    end

    context 'with biweekly frequency' do
      it 'generates orders every 2 weeks' do
        recurring_order.update(frequency: 'biweekly')

        start_date = Date.new(2025, 1, 6)  # Week 1
        end_date = Date.new(2025, 2, 3)    # Week 5

        orders = recurring_order.generate_orders_for_range(start_date, end_date)

        expect(orders.size).to eq(3)
        expect(orders.map(&:scheduled_date)).to match_array([
          Date.new(2025, 1, 6),   # Week 1
          Date.new(2025, 1, 20),  # Week 3
          Date.new(2025, 2, 3)    # Week 5
        ])
      end
    end

    context 'with monthly frequency' do
      it 'generates orders on first occurrence of the day in each month' do
        recurring_order.update(frequency: 'monthly')

        start_date = Date.new(2025, 1, 1)
        end_date = Date.new(2025, 3, 31)

        orders = recurring_order.generate_orders_for_range(start_date, end_date)

        # First Monday of Jan, Feb, Mar
        expect(orders.size).to eq(3)
        expect(orders.map(&:scheduled_date)).to match_array([
          Date.new(2025, 1, 6),   # First Monday in January
          Date.new(2025, 2, 3),   # First Monday in February
          Date.new(2025, 3, 3)    # First Monday in March
        ])
      end
    end

    it 'copies all relevant fields to generated orders' do
      order = recurring_order.generate_orders_for_range(Date.new(2025, 1, 6), Date.new(2025, 1, 6)).first

      expect(order.company_id).to eq(recurring_order.company_id)
      expect(order.restaurant_id).to eq(recurring_order.restaurant_id)
      expect(order.menu_id).to eq(recurring_order.menu_id)
      expect(order.delivery_company_id).to eq(recurring_order.delivery_company_id)
      expect(order.default_meal_count).to eq(recurring_order.default_meal_count)
      expect(order.recurring_order_id).to eq(recurring_order.id)
      expect(order.is_trial).to eq(recurring_order.is_trial)
      expect(order.collection_time).to eq(recurring_order.collection_time)
      expect(order.warehouse_pickup_time).to eq(recurring_order.warehouse_pickup_time)
      expect(order.return_location).to eq(recurring_order.return_location)
      expect(order.equipment_notes).to eq(recurring_order.equipment_notes)
    end
  end
end
