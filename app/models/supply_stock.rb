class SupplyStock < ApplicationRecord
  belongs_to :supply
  belongs_to :location, polymorphic: true, optional: true

  validates :supply_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :update_last_updated_at

  LOCATION_TYPES = ['headquarters', 'company', 'restaurant', 'warehouse'].freeze

  def self.ransackable_attributes(auth_object = nil)
    ["supply_id", "location_type", "location_id", "location_name",
     "location_type_detail", "quantity", "physical_count", "last_updated_at",
     "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["supply", "location"]
  end

  # 拠点区分の日本語名
  def location_type_japanese
    case location_type
    when 'Company' then '企業'
    when 'Restaurant' then '飲食店'
    when nil
      case location_name
      when /試食会/ then '本社'
      else '本社'
      end
    else '倉庫'
    end
  end

  # 拠点の表示名
  def location_display_name
    if location
      location.name
    else
      location_name || '本社'
    end
  end

  # 発注要否（発注点を下回っているか）
  def needs_reorder?
    return false unless supply.reorder_point
    quantity <= supply.reorder_point
  end

  # この在庫に関連する備品移動履歴を取得
  def related_movements
    SupplyMovement.where(supply_id: supply_id)
                  .where(
                    "(from_location_type = ? AND from_location_id = ?) OR (to_location_type = ? AND to_location_id = ?)",
                    location_type, location_id, location_type, location_id
                  )
                  .order(movement_date: :desc, created_at: :desc)
  end

  private

  def update_last_updated_at
    self.last_updated_at = Time.current if quantity_changed?
  end
end
