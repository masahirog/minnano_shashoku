class Driver < ApplicationRecord
  belongs_to :delivery_company

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "delivery_company_id", "id", "is_active",
     "name", "phone", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_company"]
  end
end
