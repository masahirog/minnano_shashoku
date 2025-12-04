class Invoice < ApplicationRecord
  # アソシエーション
  belongs_to :company
  has_many :invoice_items, dependent: :destroy
  has_many :orders, through: :invoice_items
  has_many :payments, dependent: :destroy

  # バリデーション
  validates :invoice_number, presence: true, uniqueness: true
  validates :issue_date, presence: true
  validates :payment_due_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[draft sent paid cancelled] }
  validates :payment_status, inclusion: { in: %w[unpaid partial paid overdue] }
  validates :billing_period_start, presence: true
  validates :billing_period_end, presence: true

  # コールバック
  before_validation :generate_invoice_number, on: :create, if: -> { invoice_number.blank? }
  before_validation :calculate_total, if: -> { subtotal.present? }

  # スコープ
  scope :draft, -> { where(status: 'draft') }
  scope :sent, -> { where(status: 'sent') }
  scope :paid, -> { where(status: 'paid') }
  scope :unpaid, -> { where(payment_status: 'unpaid') }
  scope :overdue, -> { where(payment_status: 'overdue') }
  scope :for_company, ->(company_id) { where(company_id: company_id) }
  scope :for_period, ->(start_date, end_date) { where(billing_period_start: start_date..end_date) }

  # ビジネスロジック

  # 請求書番号を自動生成（INV-YYYYMM-XXXX）
  def generate_invoice_number
    year_month = (issue_date || Date.today).strftime('%Y%m')
    last_invoice = Invoice.where('invoice_number LIKE ?', "INV-#{year_month}-%").order(invoice_number: :desc).first

    if last_invoice
      last_number = last_invoice.invoice_number.split('-').last.to_i
      next_number = last_number + 1
    else
      next_number = 1
    end

    self.invoice_number = "INV-#{year_month}-#{next_number.to_s.rjust(4, '0')}"
  end

  # 小計を計算
  def calculate_subtotal
    self.subtotal = invoice_items.sum(&:amount)
  end

  # 消費税を計算（10%）
  def calculate_tax(rate = 0.10)
    self.tax_amount = (subtotal * rate).round
  end

  # 合計金額を計算
  def calculate_total
    self.total_amount = subtotal + tax_amount
  end

  # 金額を再計算（明細から）
  def recalculate_amounts!
    calculate_subtotal
    calculate_tax
    calculate_total
    save!
  end

  # 送信済みにする
  def mark_as_sent
    update(status: 'sent')
  end

  # 支払済みにする
  def mark_as_paid
    update(status: 'paid', payment_status: 'paid')
  end

  # キャンセル
  def cancel
    update(status: 'cancelled')
  end

  # 支払期限を過ぎているか
  def overdue?
    return false if payment_status == 'paid'
    payment_due_date < Date.today
  end

  # 支払期限までの日数
  def days_until_due
    (payment_due_date - Date.today).to_i
  end

  # 支払期限を過ぎた日数
  def days_overdue
    return 0 unless overdue?
    (Date.today - payment_due_date).to_i
  end

  # 入金済み金額
  def paid_amount
    payments.sum(:amount)
  end

  # 残高（未払い金額）
  def remaining_balance
    total_amount - paid_amount
  end

  # 支払状況を更新
  def update_payment_status
    reload # paymentsの最新状態を取得

    new_payment_status = if remaining_balance <= 0
                          'paid'
                        elsif paid_amount > 0
                          'partial'
                        elsif overdue?
                          'overdue'
                        else
                          'unpaid'
                        end

    # 支払状況が変わった場合のみ更新
    if payment_status != new_payment_status
      update_column(:payment_status, new_payment_status)

      # 全額支払済みの場合はステータスも更新
      if new_payment_status == 'paid' && status != 'paid'
        update_column(:status, 'paid')
      end
    end
  end
end
