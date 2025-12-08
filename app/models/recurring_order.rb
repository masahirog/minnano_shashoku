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
end
