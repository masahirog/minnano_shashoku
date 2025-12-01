class Company < ApplicationRecord
  belongs_to :staff, optional: true
  has_many :orders

  validates :name, presence: true
  validates :formal_name, presence: true
  validates :contract_status, presence: true
end
