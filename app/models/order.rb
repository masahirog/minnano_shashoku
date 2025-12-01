class Order < ApplicationRecord
  belongs_to :company
  belongs_to :restaurant
  belongs_to :menu
  belongs_to :second_menu, class_name: 'Menu', optional: true
  belongs_to :delivery_company, optional: true
  has_many :delivery_sheet_items

  validates :order_type, presence: true
  validates :scheduled_date, presence: true
  validates :default_meal_count, presence: true
  validates :status, presence: true
end
