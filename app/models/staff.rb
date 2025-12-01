class Staff < ApplicationRecord
  self.table_name = 'staff'

  has_many :companies
  has_many :restaurants

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "role", "updated_at"]
  end
end
