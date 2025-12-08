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

  # 特定拠点での在庫を取得
  def stock_at(location_type, location_id)
    supply_stocks.find_by(location_type: location_type, location_id: location_id)
  end

  # 特定拠点での予測在庫を計算
  def predicted_stock_at(location_type, location_id, target_date = Date.today + 7.days)
    stock = stock_at(location_type, location_id)
    return 0 unless stock
    stock.predicted_quantity(target_date)
  end

  # 特定拠点で発注点を下回る日を取得
  def reorder_date_at(location_type, location_id)
    stock = stock_at(location_type, location_id)
    return nil unless stock
    stock.first_reorder_date
  end
end
