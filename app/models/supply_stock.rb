class SupplyStock < ApplicationRecord
  belongs_to :supply
  belongs_to :location, polymorphic: true, optional: true

  validates :supply_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :update_last_updated_at

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
    when 'OwnLocation' then '自社拠点'
    when 'DeliveryCompany' then '配送会社'
    else '不明'
    end
  end

  # 拠点の表示名
  def location_display_name
    location&.name || '不明'
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

  # 指定日時点の予測在庫を計算（確定 + 予定の移動を反映）
  def predicted_quantity(target_date = Date.today, include_planned: true)
    # 現在の在庫からスタート
    predicted = quantity

    # target_date以降の未来の移動のみを取得
    movements = SupplyMovement.where(supply_id: supply_id)
                              .where("movement_date > ? AND movement_date <= ?", Date.today, target_date)

    # include_planned=falseの場合は確定のみ
    movements = movements.where(status: '確定') unless include_planned

    movements.each do |movement|
      # この拠点からのピックアップ（減少）
      if movement.from_location_type == location_type && movement.from_location_id == location_id
        predicted -= movement.quantity
      end

      # この拠点への納品（増加）
      if movement.to_location_type == location_type && movement.to_location_id == location_id
        predicted += movement.quantity
      end
    end

    predicted
  end

  # 指定期間の在庫推移を計算（日ごと）
  def quantity_transitions(from_date = Date.today, to_date = Date.today + 7.days, include_planned: true)
    transitions = []
    current_qty = quantity

    (from_date..to_date).each do |date|
      # その日の移動を取得
      movements = SupplyMovement.where(supply_id: supply_id, movement_date: date)
      movements = movements.where(status: '確定') unless include_planned

      # その日の移動を反映
      day_change = 0
      movements.each do |movement|
        if movement.from_location_type == location_type && movement.from_location_id == location_id
          day_change -= movement.quantity
        end
        if movement.to_location_type == location_type && movement.to_location_id == location_id
          day_change += movement.quantity
        end
      end

      current_qty += day_change

      transitions << {
        date: date,
        quantity: current_qty,
        change: day_change,
        movements: movements.to_a
      }
    end

    transitions
  end

  # 発注点を下回る最初の日を取得
  def first_reorder_date(days_ahead = 30)
    return nil unless supply.reorder_point

    transitions = quantity_transitions(Date.today, Date.today + days_ahead.days)
    transitions.find { |t| t[:quantity] <= supply.reorder_point }&.dig(:date)
  end

  private

  def update_last_updated_at
    self.last_updated_at = Time.current if quantity_changed?
  end
end
