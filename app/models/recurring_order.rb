class RecurringOrder < ApplicationRecord
  # アソシエーション
  belongs_to :company
  belongs_to :restaurant
  belongs_to :menu, optional: true
  belongs_to :delivery_company, optional: true
  has_many :orders, dependent: :nullify

  # バリデーション
  validates :day_of_week, inclusion: { in: 0..6 }
  validates :frequency, inclusion: { in: %w[weekly biweekly monthly] }
  validates :default_meal_count, numericality: { only_integer: true, greater_than: 0 }
  validates :delivery_time, :start_date, presence: true

  validate :end_date_after_start_date
  validate :restaurant_capacity_check
  validate :restaurant_not_closed_on_day

  # スコープ
  scope :active, -> { where(is_active: true, status: 'active') }
  scope :for_day_of_week, ->(day) { where(day_of_week: day) }
  scope :current, -> { where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.today, Date.today) }

  # Order自動生成メソッド
  def generate_orders_for_range(start_date, end_date)
    generated_orders = []

    current_date = start_date
    week_count = 0

    while current_date <= end_date
      # この日が対象の曜日かチェック
      if current_date.wday == day_of_week
        # 頻度に応じて生成するかチェック
        should_generate = case frequency
        when 'weekly'
          true
        when 'biweekly'
          week_count % 2 == 0
        when 'monthly'
          # 月の第何週かを計算（簡易実装）
          current_date.day <= 7
        else
          false
        end

        if should_generate && within_active_period?(current_date)
          # 既存のOrderが存在しないかチェック
          existing_order = Order.find_by(
            recurring_order_id: id,
            scheduled_date: current_date
          )

          unless existing_order
            order = create_order_for_date(current_date)
            generated_orders << order if order.persisted?
          end
        end

        week_count += 1
      end

      current_date += 1.day
    end

    generated_orders
  end

  private

  def within_active_period?(date)
    return false if date < start_date
    return true if end_date.nil?
    date <= end_date
  end

  def create_order_for_date(date)
    Order.create(
      company_id: company_id,
      restaurant_id: restaurant_id,
      menu_id: menu_id,
      delivery_company_id: delivery_company_id,
      recurring_order_id: id,
      scheduled_date: date,
      default_meal_count: default_meal_count,
      order_type: 'recurring',
      status: 'pending',
      is_trial: is_trial,
      collection_time: collection_time,
      warehouse_pickup_time: warehouse_pickup_time,
      return_location: return_location,
      equipment_notes: equipment_notes
    )
  end

  def end_date_after_start_date
    return unless end_date.present? && start_date.present?

    if end_date < start_date
      errors.add(:end_date, 'は開始日より後の日付を指定してください')
    end
  end

  def restaurant_capacity_check
    return unless restaurant && default_meal_count

    if restaurant.capacity_per_day && default_meal_count > restaurant.capacity_per_day
      errors.add(:default_meal_count, "が飲食店の1日のキャパ（#{restaurant.capacity_per_day}食）を超えています")
    end
  end

  def restaurant_not_closed_on_day
    return unless restaurant && day_of_week.present?

    if restaurant.regular_holiday.present?
      closed_days = restaurant.regular_holiday.split(',').map(&:to_i)
      if closed_days.include?(day_of_week)
        errors.add(:day_of_week, 'は飲食店の定休日です')
      end
    end
  end
end
