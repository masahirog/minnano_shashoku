class Restaurant < ApplicationRecord
  belongs_to :admin_user, optional: true
  has_many :menus
  has_many :orders
  has_many :supply_stocks, as: :location, dependent: :destroy

  validates :name, presence: true
  validates :contract_status, presence: true
  validates :max_capacity, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["contact_email", "contact_person", "contact_phone", "contract_status",
     "created_at", "genre", "id", "max_capacity", "name", "phone",
     "pickup_time_trial_only", "pickup_time_with_main", "admin_user_id",
     "supplier_code", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["menus", "orders", "admin_user", "supply_stocks"]
  end
end
