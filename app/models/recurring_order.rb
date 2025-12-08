class RecurringOrder < ApplicationRecord
  # アソシエーション
  belongs_to :company
  has_many :orders, dependent: :nullify

  # バリデーション
  validates :day_of_week, inclusion: { in: 0..6 }
  validates :meal_count, numericality: { only_integer: true, greater_than: 0 }
  validates :delivery_time, presence: true

  # スコープ
  scope :active, -> { where(is_active: true, status: 'active') }
  scope :for_day_of_week, ->(day) { where(day_of_week: day) }

  # 曜日の日本語表示
  def day_of_week_name
    %w[日 月 火 水 木 金 土][day_of_week]
  end

  # 指定期間内でOrderを生成
  def generate_orders_for_range(from_date, to_date)
    orders = []

    (from_date..to_date).each do |date|
      # この定期案件の曜日と一致する日のみ
      next unless date.wday == day_of_week

      # 既に存在するOrderはスキップ
      next if Order.exists?(
        recurring_order_id: id,
        scheduled_date: date,
        company_id: company_id
      )

      # Orderを作成
      order = Order.create!(
        recurring_order_id: id,
        company_id: company_id,
        scheduled_date: date,
        order_type: '定期',
        total_meal_count: meal_count,
        status: '確認待ち',
        subtotal: 0,
        tax: 0,
        tax_8_percent: 0,
        tax_10_percent: 0,
        delivery_fee: 0,
        delivery_fee_tax: 0,
        discount_amount: 0,
        total_price: 0
      )

      orders << order
    end

    orders
  end
end
