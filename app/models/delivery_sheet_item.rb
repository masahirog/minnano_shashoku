class DeliverySheetItem < ApplicationRecord
  belongs_to :order
  belongs_to :driver, optional: true

  validates :delivery_date, presence: true
  validates :sequence, presence: true
  validates :action_type, presence: true
end
