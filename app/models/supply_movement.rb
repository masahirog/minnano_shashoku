class SupplyMovement < ApplicationRecord
  belongs_to :supply
  belongs_to :from_location, polymorphic: true, optional: true
  belongs_to :to_location, polymorphic: true, optional: true

  validates :supply_id, presence: true
  validates :movement_type, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :movement_date, presence: true

  MOVEMENT_TYPES = ['移動', '入荷', '消費'].freeze

  def self.ransackable_attributes(auth_object = nil)
    ["supply_id", "movement_type", "quantity", "from_location_type",
     "from_location_id", "to_location_type", "to_location_id",
     "movement_date", "notes", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["supply", "from_location", "to_location"]
  end
end
