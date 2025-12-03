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

  # Day 5-6で実装予定のメソッド
  def generate_orders_for_range(start_date, end_date)
    # 実装は後ほど
  end

  private

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
