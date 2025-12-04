class Payment < ApplicationRecord
  # アソシエーション
  belongs_to :invoice

  # バリデーション
  validates :payment_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: %w[銀行振込 クレジットカード 現金 その他], allow_blank: true }
  validate :amount_not_exceeding_remaining_balance

  # コールバック
  after_create :update_invoice_payment_status
  after_destroy :update_invoice_payment_status

  # スコープ
  scope :for_invoice, ->(invoice_id) { where(invoice_id: invoice_id) }
  scope :by_payment_date, -> { order(payment_date: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  private

  # 請求書の残高を超えないことを確認
  def amount_not_exceeding_remaining_balance
    return unless invoice && amount

    remaining = invoice.remaining_balance
    # 新規作成時は全額、更新時は自分の金額を除いた残高を計算
    remaining += amount_was.to_i if persisted?

    if amount > remaining
      errors.add(:amount, "は残高 #{remaining}円 を超えることはできません")
    end
  end

  # 請求書の支払状況を更新
  def update_invoice_payment_status
    invoice.update_payment_status if invoice
  end
end
