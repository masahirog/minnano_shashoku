require "rails_helper"

RSpec.describe InvoiceMailer, type: :mailer do
  let(:company) do
    Company.create!(
      name: 'テスト企業',
      formal_name: 'テスト企業株式会社',
      contact_email: 'test@example.com',
      billing_email: 'billing@example.com',
      contract_status: 'active'
    )
  end

  let(:invoice) do
    Invoice.create!(
      company: company,
      invoice_number: 'INV-202412-0001',
      issue_date: Date.today,
      payment_due_date: Date.today - 10.days, # 期限超過
      billing_period_start: Date.today - 30.days,
      billing_period_end: Date.today,
      subtotal: 10000,
      tax_amount: 1000,
      total_amount: 11000,
      status: 'sent'
    )
  end

  describe "overdue_notice" do
    let(:mail) { InvoiceMailer.overdue_notice(invoice) }

    it "renders the headers" do
      expect(mail.subject).to include("請求書の支払期限が過ぎています")
      expect(mail.subject).to include(invoice.invoice_number)
      expect(mail.to).to eq([company.billing_email])
      expect(mail.from).to eq(['noreply@minnano-shashoku.com'])
    end

    it "renders the body" do
      # マルチパートメールの場合、text_partまたはhtml_partを使用
      body_content = mail.text_part ? mail.text_part.body.decoded : mail.body.decoded
      expect(body_content).to match(company.name)
      expect(body_content).to match(invoice.invoice_number)
    end
  end

  describe "payment_reminder" do
    let(:upcoming_invoice) do
      Invoice.create!(
        company: company,
        invoice_number: 'INV-202412-0002',
        issue_date: Date.today,
        payment_due_date: Date.today + 5.days, # 期限間近
        billing_period_start: Date.today - 30.days,
        billing_period_end: Date.today,
        subtotal: 10000,
        tax_amount: 1000,
        total_amount: 11000,
        status: 'sent'
      )
    end

    let(:mail) { InvoiceMailer.payment_reminder(upcoming_invoice) }

    it "renders the headers" do
      expect(mail.subject).to include("請求書の支払期限が近づいています")
      expect(mail.subject).to include(upcoming_invoice.invoice_number)
      expect(mail.to).to eq([company.billing_email])
      expect(mail.from).to eq(['noreply@minnano-shashoku.com'])
    end

    it "renders the body" do
      # マルチパートメールの場合、text_partまたはhtml_partを使用
      body_content = mail.text_part ? mail.text_part.body.decoded : mail.body.decoded
      expect(body_content).to match(company.name)
      expect(body_content).to match(upcoming_invoice.invoice_number)
    end
  end

end
