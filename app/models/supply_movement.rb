class SupplyMovement < ApplicationRecord
  belongs_to :supply
  belongs_to :from_location, polymorphic: true, optional: true
  belongs_to :to_location, polymorphic: true, optional: true

  validates :supply_id, presence: true
  validates :movement_type, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :movement_date, presence: true
  validates :status, presence: true, inclusion: { in: ['予定', '確定'] }

  MOVEMENT_TYPES = ['移動', '入荷', '消費', '棚卸調整'].freeze
  STATUSES = ['予定', '確定'].freeze

  after_create :update_stock

  def self.ransackable_attributes(auth_object = nil)
    ["supply_id", "movement_type", "quantity", "from_location_type",
     "from_location_id", "to_location_type", "to_location_id",
     "movement_date", "status", "notes", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["supply", "from_location", "to_location"]
  end

  private

  def update_stock
    # 「確定」のみ在庫を更新（「予定」は在庫に反映しない）
    return unless status == '確定'

    case movement_type
    when '入荷'
      # 納品先の在庫を増やす
      increase_stock(to_location_type, to_location_id, quantity)
    when '消費'
      # ピックアップ先の在庫を減らす
      decrease_stock(from_location_type, from_location_id, quantity)
    when '移動'
      # ピックアップ先の在庫を減らし、納品先の在庫を増やす
      decrease_stock(from_location_type, from_location_id, quantity)
      increase_stock(to_location_type, to_location_id, quantity)
    when '棚卸調整'
      # 納品先の在庫を調整（棚卸の差異を反映）
      # quantityが正なら増加、負なら減少
      if quantity > 0
        increase_stock(to_location_type, to_location_id, quantity)
      else
        decrease_stock(to_location_type, to_location_id, quantity.abs)
      end
    end
  end

  def increase_stock(location_type, location_id, qty)
    stock = find_or_create_stock(location_type, location_id)
    stock.update!(quantity: stock.quantity + qty)
  end

  def decrease_stock(location_type, location_id, qty)
    stock = find_or_create_stock(location_type, location_id)
    stock.update!(quantity: stock.quantity - qty)
  end

  def find_or_create_stock(location_type, location_id)
    SupplyStock.find_or_create_by!(
      supply_id: supply_id,
      location_type: location_type,
      location_id: location_id
    ) do |s|
      s.quantity = 0
    end
  end
end
