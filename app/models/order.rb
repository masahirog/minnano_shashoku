class Order < ApplicationRecord
  belongs_to :company
  belongs_to :restaurant
  belongs_to :menu
  belongs_to :second_menu, class_name: 'Menu', optional: true
  belongs_to :delivery_company, optional: true
  belongs_to :recurring_order, optional: true
  has_many :delivery_sheet_items

  validates :order_type, presence: true
  validates :scheduled_date, presence: true
  validates :default_meal_count, presence: true
  validates :status, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["company_id", "confirmed_meal_count", "created_at", "default_meal_count",
     "delivery_company_id", "delivery_company_status", "delivery_group",
     "delivery_priority", "id", "menu_id", "order_type", "restaurant_id",
     "restaurant_status", "scheduled_date", "second_menu_id", "status", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["company", "delivery_company", "delivery_sheet_items", "menu", "restaurant", "second_menu"]
  end

  # 同じ週に同じメニューが重複しているかチェック
  def duplicate_menu_in_week?
    return false unless scheduled_date && restaurant_id && menu_id

    # 週の開始（月曜日）と終了（日曜日）を計算
    week_start = scheduled_date.beginning_of_week(:monday)
    week_end = scheduled_date.end_of_week(:monday)

    # 同じ週内で、同じrestaurant_idとmenu_idを持つOrderがあるかチェック（自分自身を除く）
    Order.where(restaurant_id: restaurant_id, menu_id: menu_id)
         .where(scheduled_date: week_start..week_end)
         .where.not(id: id)
         .exists?
  end
end
