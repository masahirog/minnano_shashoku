class Staff < ApplicationRecord
  has_many :companies
  has_many :restaurants

  validates :name, presence: true
end
