# Preview all emails at http://localhost:3000/rails/mailers/invoice_mailer_mailer
class InvoiceMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/invoice_mailer_mailer/overdue_notice
  def overdue_notice
    InvoiceMailer.overdue_notice
  end

  # Preview this email at http://localhost:3000/rails/mailers/invoice_mailer_mailer/payment_reminder
  def payment_reminder
    InvoiceMailer.payment_reminder
  end

end
