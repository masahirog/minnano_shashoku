class DeliveryCompany < ApplicationRecord
  has_many :drivers
  has_many :orders

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["contact_person", "created_at", "email", "id", "is_active",
     "name", "phone", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["drivers", "orders"]
  end
end
