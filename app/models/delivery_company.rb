class DeliveryCompany < ApplicationRecord
  has_many :drivers
  has_many :orders

  validates :name, presence: true
end
