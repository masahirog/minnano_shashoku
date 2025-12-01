class Staff < ApplicationRecord
  self.table_name = 'staff'

  has_many :companies
  has_many :restaurants

  validates :name, presence: true
end
