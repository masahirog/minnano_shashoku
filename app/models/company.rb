class Company < ApplicationRecord
  belongs_to :staff, optional: true
  has_many :orders

  validates :name, presence: true
  validates :formal_name, presence: true
  validates :contract_status, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["contact_email", "contact_person", "contact_phone", "contract_status",
     "created_at", "default_meal_count", "formal_name", "id", "name",
     "staff_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["orders", "staff"]
  end
end
