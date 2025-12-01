class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :orders

  validates :name, presence: true
  validates :price_per_meal, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "id", "is_active", "name",
     "price_per_meal", "restaurant_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["orders", "restaurant"]
  end
end
