class DeliverySheetItem < ApplicationRecord
  belongs_to :order
  belongs_to :driver, optional: true

  validates :delivery_date, presence: true
  validates :sequence, presence: true
  validates :action_type, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["action_type", "address", "created_at", "delivery_date", "delivery_type",
     "driver_id", "has_setup", "id", "location_name", "location_type",
     "meal_info", "notes", "order_id", "phone", "scheduled_time",
     "sequence", "supplies_info", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["driver", "order"]
  end
end
