class InvoiceMailer < ApplicationMailer
  default from: 'noreply@minnano-shashoku.com'

  # 期限超過通知メール
  def overdue_notice(invoice)
    @invoice = invoice
    @company = invoice.company
    @days_overdue = invoice.days_overdue
    @remaining_balance = invoice.remaining_balance

    mail(
      to: @company.billing_email || @company.contact_email,
      subject: "【重要】請求書の支払期限が過ぎています - #{@invoice.invoice_number}"
    )
  end

  # 支払リマインダーメール
  def payment_reminder(invoice)
    @invoice = invoice
    @company = invoice.company
    @days_until_due = invoice.days_until_due
    @remaining_balance = invoice.remaining_balance

    mail(
      to: @company.billing_email || @company.contact_email,
      subject: "【お知らせ】請求書の支払期限が近づいています - #{@invoice.invoice_number}"
    )
  end
end
