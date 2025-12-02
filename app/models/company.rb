class Company < ApplicationRecord
  belongs_to :staff, optional: true
  has_many :orders
  has_many :supply_stocks, as: :location, dependent: :destroy

  validates :name, presence: true
  validates :formal_name, presence: true
  validates :contract_status, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["contact_email", "contact_person", "contact_phone", "contract_status",
     "created_at", "default_meal_count", "formal_name", "id", "name",
     "staff_id", "updated_at", "delivery_day_of_week", "has_setup",
     "digital_signage_id", "first_delivery_date", "discount_campaign_end_date",
     "trial_billable", "trial_free_meal_count", "trial_date",
     "employee_burden_enabled", "employee_burden_amount", "delivery_time_goal",
     "pickup_time_goal", "delivery_notes", "pickup_notes", "monthly_fee_type",
     "initial_fee_amount", "delivery_fee_campaign_end_date",
     "delivery_fee_discount", "remote_delivery_fee", "special_delivery_fee"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["orders", "staff", "supply_stocks"]
  end
end
