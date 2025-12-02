class OwnLocation < ApplicationRecord
  has_many :supply_stocks, as: :location, dependent: :destroy

  validates :name, presence: true
  validates :location_type, presence: true

  LOCATION_TYPES = ['倉庫', 'オフィス', 'その他'].freeze

  def self.ransackable_attributes(auth_object = nil)
    ["name", "location_type", "address", "phone", "is_active",
     "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["supply_stocks"]
  end
end
