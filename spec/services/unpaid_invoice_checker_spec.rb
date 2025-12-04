require 'rails_helper'

RSpec.describe UnpaidInvoiceChecker do
  let(:checker) { UnpaidInvoiceChecker.new }
  let(:company1) { Company.create!(name: '企業A', formal_name: '株式会社企業A', contract_status: 'active', billing_email: 'companyA@example.com') }
  let(:company2) { Company.create!(name: '企業B', formal_name: '株式会社企業B', contract_status: 'active', billing_email: 'companyB@example.com') }

  before do
    # メール送信をモック
    allow(InvoiceMailer).to receive(:overdue_notice).and_return(double(deliver_later: true))
    allow(InvoiceMailer).to receive(:payment_reminder).and_return(double(deliver_later: true))
  end

  describe '#check_overdue' do
    it '期限超過の請求書を検出する' do
      # 企業を明示的に作成
      c1 = company1
      c2 = company2

      # 期限超過の請求書（未払い）
      # 期限内の日付で作成してから、期限超過の日付に変更
      invoice1 = Invoice.create!(
        company: c1,
        invoice_number: 'INV-TEST-0001',
        issue_date: Date.today - 40.days,
        payment_due_date: Date.today + 10.days, # 一旦期限内で作成
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'sent',
        payment_status: 'unpaid'
      )
      # 期限超過の日付に変更（コールバックをスキップ）
      invoice1.update_columns(payment_due_date: Date.today - 10.days)

      # 期限超過の請求書（一部入金）
      invoice2 = Invoice.create!(
        company: c2,
        invoice_number: 'INV-TEST-0002',
        issue_date: Date.today - 40.days,
        payment_due_date: Date.today + 5.days, # 一旦期限内で作成
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 18182,
        tax_amount: 1818,
        total_amount: 20000,
        status: 'sent',
        payment_status: 'unpaid'
      )
      # Paymentを作成（after_createでupdate_payment_statusが呼ばれる）
      payment = Payment.new(invoice: invoice2, payment_date: Date.today - 3.days, amount: 10000)
      payment.save(validate: false) # バリデーションをスキップ
      # 期限超過の日付に変更し、payment_statusを'partial'に設定（コールバックをスキップ）
      invoice2.update_columns(payment_due_date: Date.today - 5.days, payment_status: 'partial')

      # 期限内の請求書（未払い）- 検出されないはず
      Invoice.create!(
        company: c1,
        invoice_number: 'INV-TEST-0003',
        issue_date: Date.today,
        payment_due_date: Date.today + 30.days,
        billing_period_start: Date.today,
        billing_period_end: Date.today,
        subtotal: 13636,
        tax_amount: 1364,
        total_amount: 15000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      # 支払済み（期限超過日付だが）- 検出されないはず
      Invoice.create!(
        company: c2,
        invoice_number: 'INV-TEST-0004',
        issue_date: Date.today - 40.days,
        payment_due_date: Date.today - 10.days,
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'paid',
        payment_status: 'paid'
      )

      overdue_invoices = checker.check_overdue

      expect(overdue_invoices.count).to eq(2)
      expect(overdue_invoices.map(&:payment_status)).to match_array(['overdue', 'overdue'])
    end

    it '請求書のステータスをoverdueに更新する' do
      invoice = Invoice.create!(
        company: company1,
        invoice_number: 'INV-TEST-0005',
        issue_date: Date.today - 40.days,
        payment_due_date: Date.today - 10.days,
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      checker.check_overdue

      invoice.reload
      expect(invoice.payment_status).to eq('overdue')
    end
  end

  describe '#check_upcoming_due' do
    it '支払期限が近い請求書を検出する（デフォルト7日以内）' do
      # 期限5日前（検出されるはず）
      Invoice.create!(
        company: company1,
        invoice_number: 'INV-TEST-0006',
        issue_date: Date.today - 25.days,
        payment_due_date: Date.today + 5.days,
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      # 期限3日前（検出されるはず）
      Invoice.create!(
        company: company2,
        invoice_number: 'INV-TEST-0007',
        issue_date: Date.today - 27.days,
        payment_due_date: Date.today + 3.days,
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 18182,
        tax_amount: 1818,
        total_amount: 20000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      # 期限10日前（検出されないはず）
      Invoice.create!(
        company: company1,
        invoice_number: 'INV-TEST-0008',
        issue_date: Date.today - 20.days,
        payment_due_date: Date.today + 10.days,
        billing_period_start: Date.today,
        billing_period_end: Date.today,
        subtotal: 13636,
        tax_amount: 1364,
        total_amount: 15000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      # 支払済み（検出されないはず）
      Invoice.create!(
        company: company2,
        invoice_number: 'INV-TEST-0009',
        issue_date: Date.today - 27.days,
        payment_due_date: Date.today + 3.days,
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'paid',
        payment_status: 'paid'
      )

      reminder_invoices = checker.check_upcoming_due

      expect(reminder_invoices.count).to eq(2)
    end

    it '期限までの日数を指定できる' do
      # 期限10日前
      Invoice.create!(
        company: company1,
        invoice_number: 'INV-TEST-0010',
        issue_date: Date.today - 20.days,
        payment_due_date: Date.today + 10.days,
        billing_period_start: Date.today,
        billing_period_end: Date.today,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      # 期限15日前
      Invoice.create!(
        company: company2,
        invoice_number: 'INV-TEST-0011',
        issue_date: Date.today - 15.days,
        payment_due_date: Date.today + 15.days,
        billing_period_start: Date.today,
        billing_period_end: Date.today,
        subtotal: 18182,
        tax_amount: 1818,
        total_amount: 20000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      # 14日以内の請求書を検出
      reminder_invoices = checker.check_upcoming_due(14)

      expect(reminder_invoices.count).to eq(1)
    end
  end

  describe '#check_all' do
    it '期限超過と期限間近の両方をチェックする' do
      # 期限超過
      invoice_overdue = Invoice.create!(
        company: company1,
        invoice_number: 'INV-TEST-0012',
        issue_date: Date.today - 40.days,
        payment_due_date: Date.today + 10.days, # 一旦期限内で作成
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'sent',
        payment_status: 'unpaid'
      )
      # 期限超過に変更
      invoice_overdue.update_columns(payment_due_date: Date.today - 10.days)

      # 期限間近
      Invoice.create!(
        company: company2,
        invoice_number: 'INV-TEST-0013',
        issue_date: Date.today - 25.days,
        payment_due_date: Date.today + 5.days,
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 18182,
        tax_amount: 1818,
        total_amount: 20000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      result = checker.check_all

      expect(result[:overdue_count]).to eq(1)
      expect(result[:reminder_count]).to eq(1)
      expect(result[:total_overdue_amount]).to eq(10000)
      expect(result[:total_reminder_amount]).to eq(20000)
    end
  end

  describe '#send_overdue_alerts' do
    it '期限超過の請求書に対してアラートメールを送信する' do
      invoice = Invoice.create!(
        company: company1,
        invoice_number: 'INV-TEST-0014',
        issue_date: Date.today - 40.days,
        payment_due_date: Date.today + 10.days, # 一旦期限内で作成
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'sent',
        payment_status: 'unpaid'
      )
      # 期限超過に変更
      invoice.update_columns(payment_due_date: Date.today - 10.days)

      expect(InvoiceMailer).to receive(:overdue_notice).with(invoice).and_call_original
      sent_count = checker.send_overdue_alerts

      expect(sent_count).to eq(1)
    end
  end

  describe '#send_payment_reminders' do
    it '期限間近の請求書に対してリマインダーメールを送信する' do
      invoice = Invoice.create!(
        company: company1,
        invoice_number: 'INV-TEST-0015',
        issue_date: Date.today - 25.days,
        payment_due_date: Date.today + 5.days,
        billing_period_start: Date.today - 60.days,
        billing_period_end: Date.today - 30.days,
        subtotal: 9091,
        tax_amount: 909,
        total_amount: 10000,
        status: 'sent',
        payment_status: 'unpaid'
      )

      expect(InvoiceMailer).to receive(:payment_reminder).with(invoice).and_call_original
      sent_count = checker.send_payment_reminders

      expect(sent_count).to eq(1)
    end
  end
end
