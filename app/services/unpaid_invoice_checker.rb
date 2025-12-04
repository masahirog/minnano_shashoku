class UnpaidInvoiceChecker
  attr_reader :overdue_invoices, :reminder_invoices

  def initialize
    @overdue_invoices = []
    @reminder_invoices = []
  end

  # 期限超過の請求書をチェック
  def check_overdue
    @overdue_invoices = Invoice
                         .where(payment_status: ['unpaid', 'partial'])
                         .where('payment_due_date < ?', Date.today)
                         .includes(:company)
                         .order(payment_due_date: :asc)

    @overdue_invoices.each do |invoice|
      update_overdue_status(invoice)
    end

    @overdue_invoices
  end

  # 支払期限が近い請求書をチェック（7日以内）
  def check_upcoming_due(days = 7)
    @reminder_invoices = Invoice
                          .where(payment_status: ['unpaid', 'partial'])
                          .where(payment_due_date: Date.today..Date.today + days.days)
                          .includes(:company)
                          .order(payment_due_date: :asc)

    @reminder_invoices
  end

  # 期限超過アラートメールを送信
  def send_overdue_alerts
    check_overdue

    @overdue_invoices.each do |invoice|
      # 企業の担当者にメール送信
      if invoice.company.billing_email.present?
        InvoiceMailer.overdue_notice(invoice).deliver_later
      end

      # 管理者にも通知
      notify_admin_overdue(invoice)
    end

    @overdue_invoices.count
  end

  # 支払リマインダーメールを送信
  def send_payment_reminders(days = 7)
    check_upcoming_due(days)

    @reminder_invoices.each do |invoice|
      if invoice.company.billing_email.present?
        InvoiceMailer.payment_reminder(invoice).deliver_later
      end
    end

    @reminder_invoices.count
  end

  # 全てのチェックを実行
  def check_all
    check_overdue
    check_upcoming_due

    {
      overdue_count: @overdue_invoices.count,
      reminder_count: @reminder_invoices.count,
      total_overdue_amount: @overdue_invoices.sum(&:remaining_balance),
      total_reminder_amount: @reminder_invoices.sum(&:remaining_balance)
    }
  end

  private

  # 請求書を期限超過ステータスに更新
  def update_overdue_status(invoice)
    if invoice.payment_status != 'overdue' && invoice.payment_status != 'paid'
      invoice.update_column(:payment_status, 'overdue')
    end
  end

  # 管理者に期限超過を通知
  def notify_admin_overdue(invoice)
    # 将来的に管理者への通知機能を実装
    # AdminUser.where(role: 'admin').each do |admin|
    #   InvoiceMailer.admin_overdue_notice(admin, invoice).deliver_later
    # end
    Rails.logger.info "[UnpaidInvoiceChecker] Overdue invoice: #{invoice.invoice_number} (#{invoice.company.name})"
  end
end
