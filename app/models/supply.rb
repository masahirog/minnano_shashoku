class Supply < ApplicationRecord
  has_many :supply_stocks, dependent: :destroy
  has_many :supply_movements, dependent: :destroy

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :category, presence: true
  validates :unit, presence: true

  CATEGORIES = ['使い捨て備品', '企業貸与備品', '飲食店貸与備品'].freeze

  def self.ransackable_attributes(auth_object = nil)
    ["name", "sku", "category", "unit", "reorder_point", "is_active",
     "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["supply_stocks", "supply_movements"]
  end

  # 総在庫数（全拠点の合計）
  def total_stock
    supply_stocks.sum(:quantity)
  end

  # 発注要否
  def needs_reorder?
    return false unless reorder_point
    total_stock <= reorder_point
  end
end
