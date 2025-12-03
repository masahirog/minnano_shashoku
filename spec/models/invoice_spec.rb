require 'rails_helper'

RSpec.describe Invoice, type: :model do
  let(:company) { Company.create!(name: 'テスト企業', formal_name: 'テスト企業株式会社', contract_status: 'active') }
  let(:invoice) do
    Invoice.create!(
      company: company,
      issue_date: Date.today,
      payment_due_date: Date.today + 30.days,
      billing_period_start: Date.today.beginning_of_month,
      billing_period_end: Date.today.end_of_month,
      subtotal: 10000,
      tax_amount: 1000,
      total_amount: 11000,
      status: 'draft',
      payment_status: 'unpaid'
    )
  end

  describe 'アソシエーション' do
    it 'companyに属する' do
      expect(invoice.company).to eq(company)
    end

    it 'invoice_itemsを持つ' do
      item = invoice.invoice_items.create!(description: 'テスト', quantity: 1, unit_price: 100, amount: 100)
      expect(invoice.invoice_items).to include(item)
    end
  end

  describe 'バリデーション' do
    it '請求書番号がない場合、無効' do
      invoice.invoice_number = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:invoice_number]).to be_present
    end

    it '発行日がない場合、無効' do
      new_invoice = Invoice.new(company: company, payment_due_date: Date.today, billing_period_start: Date.today, billing_period_end: Date.today, total_amount: 0)
      expect(new_invoice).not_to be_valid
      expect(new_invoice.errors[:issue_date]).to be_present
    end

    it '合計金額が負の場合、無効' do
      new_invoice = Invoice.new(company: company, issue_date: Date.today, payment_due_date: Date.today, billing_period_start: Date.today, billing_period_end: Date.today, subtotal: nil, tax_amount: nil, total_amount: -100)
      new_invoice.invoice_number = 'TEST-001'  # 自動生成をスキップ
      expect(new_invoice).not_to be_valid
      expect(new_invoice.errors[:total_amount]).to be_present
    end
  end

  describe 'スコープ' do
    before do
      @draft = Invoice.create!(company: company, issue_date: Date.today, payment_due_date: Date.today + 30.days,
                               billing_period_start: Date.today, billing_period_end: Date.today, total_amount: 10000, status: 'draft')
      @sent = Invoice.create!(company: company, issue_date: Date.today, payment_due_date: Date.today + 30.days,
                              billing_period_start: Date.today, billing_period_end: Date.today, total_amount: 10000, status: 'sent')
      @paid = Invoice.create!(company: company, issue_date: Date.today, payment_due_date: Date.today + 30.days,
                              billing_period_start: Date.today, billing_period_end: Date.today, total_amount: 10000, status: 'paid', payment_status: 'paid')
    end

    it 'draftスコープは下書きのみを返す' do
      expect(Invoice.draft).to include(@draft)
      expect(Invoice.draft).not_to include(@sent, @paid)
    end

    it 'sentスコープは送信済みのみを返す' do
      expect(Invoice.sent).to include(@sent)
      expect(Invoice.sent).not_to include(@draft, @paid)
    end

    it 'paidスコープは支払済みのみを返す' do
      expect(Invoice.paid).to include(@paid)
      expect(Invoice.paid).not_to include(@draft, @sent)
    end
  end

  describe '#generate_invoice_number' do
    it '請求書番号が自動生成される（INV-YYYYMM-XXXX形式）' do
      new_invoice = Invoice.create!(
        company: company,
        issue_date: Date.today,
        payment_due_date: Date.today + 30.days,
        billing_period_start: Date.today,
        billing_period_end: Date.today,
        total_amount: 10000
      )

      expect(new_invoice.invoice_number).to match(/^INV-\d{6}-\d{4}$/)
    end

    it '同じ月の請求書番号は連番になる' do
      invoice1 = Invoice.create!(company: company, issue_date: Date.today, payment_due_date: Date.today + 30.days,
                                 billing_period_start: Date.today, billing_period_end: Date.today, total_amount: 10000)
      invoice2 = Invoice.create!(company: company, issue_date: Date.today, payment_due_date: Date.today + 30.days,
                                 billing_period_start: Date.today, billing_period_end: Date.today, total_amount: 10000)

      number1 = invoice1.invoice_number.split('-').last.to_i
      number2 = invoice2.invoice_number.split('-').last.to_i

      expect(number2).to eq(number1 + 1)
    end
  end

  describe '#calculate_subtotal' do
    it '明細から小計を計算する' do
      invoice.invoice_items.create!(description: '商品A', quantity: 2, unit_price: 1000, amount: 2000)
      invoice.invoice_items.create!(description: '商品B', quantity: 3, unit_price: 1500, amount: 4500)

      invoice.calculate_subtotal

      expect(invoice.subtotal).to eq(6500)
    end
  end

  describe '#calculate_tax' do
    it '消費税を計算する（10%）' do
      invoice.subtotal = 10000
      invoice.calculate_tax

      expect(invoice.tax_amount).to eq(1000)
    end
  end

  describe '#mark_as_sent' do
    it 'ステータスを送信済みに変更する' do
      invoice.mark_as_sent
      expect(invoice.status).to eq('sent')
    end
  end

  describe '#mark_as_paid' do
    it 'ステータスを支払済みに変更する' do
      invoice.mark_as_paid
      expect(invoice.status).to eq('paid')
      expect(invoice.payment_status).to eq('paid')
    end
  end

  describe '#overdue?' do
    it '支払期限を過ぎている場合、trueを返す' do
      invoice.update(payment_due_date: Date.today - 1.day, payment_status: 'unpaid')
      expect(invoice.overdue?).to be true
    end

    it '支払期限内の場合、falseを返す' do
      invoice.update(payment_due_date: Date.today + 1.day, payment_status: 'unpaid')
      expect(invoice.overdue?).to be false
    end

    it '支払済みの場合、falseを返す' do
      invoice.update(payment_due_date: Date.today - 1.day, payment_status: 'paid')
      expect(invoice.overdue?).to be false
    end
  end

  describe '#days_until_due' do
    it '支払期限までの日数を返す' do
      invoice.update(payment_due_date: Date.today + 10.days)
      expect(invoice.days_until_due).to eq(10)
    end
  end

  describe '#days_overdue' do
    it '支払期限を過ぎた日数を返す' do
      invoice.update(payment_due_date: Date.today - 5.days, payment_status: 'unpaid')
      expect(invoice.days_overdue).to eq(5)
    end

    it '支払期限内の場合、0を返す' do
      invoice.update(payment_due_date: Date.today + 5.days)
      expect(invoice.days_overdue).to eq(0)
    end
  end
end
