class Restaurant < ApplicationRecord
  belongs_to :staff, optional: true
  has_many :menus
  has_many :orders

  validates :name, presence: true
  validates :contract_status, presence: true
  validates :max_capacity, presence: true
end
