class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, through: :order_items
  has_one_attached :photo

  TAX_RATES = [8, 10].freeze
  TAX_RATE_OPTIONS = [["8%", 8], ["10%", 10]].freeze

  validates :name, presence: true
  validates :price_per_meal, presence: true
  validates :tax_rate, presence: true, inclusion: { in: TAX_RATES }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "id", "is_active", "name",
     "price_per_meal", "restaurant_id", "tax_rate", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["order_items", "orders", "restaurant"]
  end
end
