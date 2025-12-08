class SupplyInventory < ApplicationRecord
  belongs_to :supply
  belongs_to :location, polymorphic: true, optional: true
  belongs_to :admin_user, optional: true

  validates :supply_id, presence: true
  validates :inventory_date, presence: true
  validates :theoretical_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :actual_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_difference
  after_create :create_adjustment_movement

  def self.ransackable_attributes(auth_object = nil)
    ["supply_id", "location_type", "location_id", "inventory_date",
     "theoretical_quantity", "actual_quantity", "difference",
     "notes", "admin_user_id", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["supply", "location", "admin_user"]
  end

  # 拠点の表示名
  def location_display_name
    location&.name || '不明'
  end

  private

  def calculate_difference
    self.difference = actual_quantity - theoretical_quantity
  end

  def create_adjustment_movement
    # 差異がある場合のみ調整用SupplyMovementを作成
    return if difference.nil? || difference.zero?

    SupplyMovement.create!(
      supply_id: supply_id,
      movement_type: '棚卸調整',
      quantity: difference.abs,
      from_location_type: difference.negative? ? location_type : nil,
      from_location_id: difference.negative? ? location_id : nil,
      to_location_type: difference.positive? ? location_type : nil,
      to_location_id: difference.positive? ? location_id : nil,
      movement_date: inventory_date,
      status: '確定',
      notes: "棚卸調整 (棚卸ID: #{id}, 差異: #{difference})"
    )
  end
end
