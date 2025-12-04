require 'rails_helper'

RSpec.describe Payment, type: :model do
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
      status: 'sent',
      payment_status: 'unpaid'
    )
  end
  let(:payment) do
    Payment.create!(
      invoice: invoice,
      payment_date: Date.today,
      amount: 5000,
      payment_method: '銀行振込'
    )
  end

  describe 'アソシエーション' do
    it 'invoiceに属する' do
      expect(payment.invoice).to eq(invoice)
    end
  end

  describe 'バリデーション' do
    it '入金日がない場合、無効' do
      payment.payment_date = nil
      expect(payment).not_to be_valid
      expect(payment.errors[:payment_date]).to be_present
    end

    it '金額がない場合、無効' do
      payment.amount = nil
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to be_present
    end

    it '金額が0以下の場合、無効' do
      payment.amount = 0
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to be_present

      payment.amount = -1000
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to be_present
    end

    it '金額が残高を超える場合、無効' do
      invoice.update(total_amount: 11000)
      invoice.payments.create!(payment_date: Date.today, amount: 5000)

      new_payment = Payment.new(
        invoice: invoice,
        payment_date: Date.today,
        amount: 7000  # 残高6000を超える
      )

      expect(new_payment).not_to be_valid
      expect(new_payment.errors[:amount]).to be_present
    end

    it '金額が残高以内の場合、有効' do
      invoice.update(total_amount: 11000)
      invoice.payments.create!(payment_date: Date.today, amount: 5000)

      new_payment = Payment.new(
        invoice: invoice,
        payment_date: Date.today,
        amount: 6000  # 残高6000と同額
      )

      expect(new_payment).to be_valid
    end
  end

  describe 'コールバック' do
    describe 'after_create :update_invoice_payment_status' do
      it '入金後、請求書の支払ステータスが更新される' do
        invoice.update(total_amount: 11000, payment_status: 'unpaid')

        # 一部入金
        invoice.payments.create!(payment_date: Date.today, amount: 5000)
        invoice.reload
        expect(invoice.payment_status).to eq('partial')

        # 残額入金
        invoice.payments.create!(payment_date: Date.today, amount: 6000)
        invoice.reload
        expect(invoice.payment_status).to eq('paid')
      end
    end

    describe 'after_destroy :update_invoice_payment_status' do
      it '入金削除後、請求書の支払ステータスが更新される' do
        invoice.update(total_amount: 11000, payment_status: 'unpaid')

        payment1 = invoice.payments.create!(payment_date: Date.today, amount: 5000)
        payment2 = invoice.payments.create!(payment_date: Date.today, amount: 6000)
        invoice.reload
        expect(invoice.payment_status).to eq('paid')

        # 入金を削除
        payment2.destroy
        invoice.reload
        expect(invoice.payment_status).to eq('partial')

        payment1.destroy
        invoice.reload
        expect(invoice.payment_status).to eq('unpaid')
      end
    end
  end

  describe '支払方法' do
    it '支払方法を記録できる' do
      payment1 = Payment.create!(invoice: invoice, payment_date: Date.today, amount: 3000, payment_method: '銀行振込')
      payment2 = Payment.create!(invoice: invoice, payment_date: Date.today, amount: 2000, payment_method: 'クレジットカード')

      expect(payment1.payment_method).to eq('銀行振込')
      expect(payment2.payment_method).to eq('クレジットカード')
    end
  end

  describe '参照番号' do
    it '参照番号を記録できる' do
      payment = Payment.create!(
        invoice: invoice,
        payment_date: Date.today,
        amount: 5000,
        reference_number: 'REF-2025-001'
      )

      expect(payment.reference_number).to eq('REF-2025-001')
    end
  end
end
