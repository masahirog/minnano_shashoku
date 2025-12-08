class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :menu

  DISCOUNT_TYPES = ['percentage', 'fixed_amount'].freeze

  TAX_RATES = [8, 10].freeze

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_type, inclusion: { in: DISCOUNT_TYPES, allow_nil: true }
  validates :tax_rate, presence: true, inclusion: { in: TAX_RATES }

  validate :menu_matches_restaurant

  before_validation :set_tax_rate_from_menu
  before_validation :calculate_discount
  before_validation :calculate_subtotal

  def self.ransackable_attributes(auth_object = nil)
    ["order_id", "menu_id", "quantity", "unit_price", "subtotal", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["order", "menu"]
  end

  private

  def set_tax_rate_from_menu
    return unless menu

    # メニューから税率をコピー（まだ設定されていない場合）
    self.tax_rate = menu.tax_rate if tax_rate.nil? || tax_rate.zero?
  end

  def calculate_discount
    return unless quantity && unit_price && discount_type && discount_value

    base_amount = quantity.to_i * unit_price.to_f

    case discount_type
    when 'percentage'
      # パーセント引き
      self.discount_amount = (base_amount * discount_value.to_f / 100.0).round
    when 'fixed_amount'
      # 円引き
      self.discount_amount = discount_value.to_f.round
    else
      self.discount_amount = 0
    end
  end

  def calculate_subtotal
    if quantity && unit_price
      base_amount = quantity.to_i * unit_price.to_f
      discount = discount_amount.to_f
      # 小計は整数に丸める
      self.subtotal = (base_amount - discount).round
    end
  end

  def menu_matches_restaurant
    return unless order&.restaurant_id && menu&.restaurant_id

    if menu.restaurant_id != order.restaurant_id
      errors.add(:menu_id, "選択したメニュー「#{menu.name}」は案件の飲食店「#{order.restaurant.name}」のメニューではありません")
    end
  end
end
