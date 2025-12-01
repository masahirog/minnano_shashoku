class Driver < ApplicationRecord
  belongs_to :delivery_company
  has_many :delivery_sheet_items

  validates :name, presence: true
end
