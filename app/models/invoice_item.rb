class InvoiceItem < ApplicationRecord
  # アソシエーション
  belongs_to :invoice
  belongs_to :order, optional: true

  # バリデーション
  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: true
  validates :amount, numericality: true

  # コールバック
  before_validation :calculate_amount
  after_save :update_invoice_total
  after_destroy :update_invoice_total

  private

  # 金額を計算（数量 × 単価）
  def calculate_amount
    self.amount = quantity * unit_price if quantity.present? && unit_price.present?
  end

  # 請求書の合計金額を更新
  def update_invoice_total
    invoice.recalculate_amounts! if invoice.present?
  end
end
