require 'rails_helper'

RSpec.describe InvoiceItem, type: :model do
  let(:company) { Company.create!(name: 'テスト企業', formal_name: 'テスト企業株式会社', contract_status: 'active') }
  let(:invoice) do
    Invoice.create!(
      company: company,
      issue_date: Date.today,
      payment_due_date: Date.today + 30.days,
      billing_period_start: Date.today,
      billing_period_end: Date.today,
      total_amount: 0
    )
  end
  let(:invoice_item) do
    InvoiceItem.create!(
      invoice: invoice,
      description: 'テスト商品',
      quantity: 2,
      unit_price: 1000,
      amount: 2000
    )
  end

  describe 'アソシエーション' do
    it 'invoiceに属する' do
      expect(invoice_item.invoice).to eq(invoice)
    end

    it 'orderに属する（optional）' do
      expect(invoice_item.order).to be_nil
    end
  end

  describe 'バリデーション' do
    it '説明がない場合、無効' do
      invoice_item.description = nil
      expect(invoice_item).not_to be_valid
      expect(invoice_item.errors[:description]).to be_present
    end

    it '数量が0以下の場合、無効' do
      invoice_item.quantity = 0
      expect(invoice_item).not_to be_valid
      expect(invoice_item.errors[:quantity]).to be_present
    end

    it '単価が数値でない場合、無効' do
      invoice_item.unit_price = 'invalid'
      expect(invoice_item).not_to be_valid
      expect(invoice_item.errors[:unit_price]).to be_present
    end
  end

  describe '#calculate_amount' do
    it '金額が自動計算される（数量 × 単価）' do
      item = InvoiceItem.new(
        invoice: invoice,
        description: 'テスト商品',
        quantity: 3,
        unit_price: 1500
      )

      item.save!

      expect(item.amount).to eq(4500)
    end

    it '数量または単価が変更されると金額が再計算される' do
      invoice_item.quantity = 5
      invoice_item.save!

      expect(invoice_item.amount).to eq(5000)
    end
  end

  describe '#update_invoice_total' do
    it '明細が保存されると請求書の合計が更新される' do
      # 初期状態
      invoice.update(subtotal: 0, tax_amount: 0, total_amount: 0)

      # 明細を作成
      invoice.invoice_items.create!(description: '商品A', quantity: 2, unit_price: 1000, amount: 2000)

      # 請求書をリロード
      invoice.reload

      # 小計、消費税、合計が更新されている
      expect(invoice.subtotal).to eq(2000)
      expect(invoice.tax_amount).to eq(200)
      expect(invoice.total_amount).to eq(2200)
    end

    it '明細が削除されると請求書の合計が更新される' do
      # 明細を作成
      item1 = invoice.invoice_items.create!(description: '商品A', quantity: 2, unit_price: 1000, amount: 2000)
      item2 = invoice.invoice_items.create!(description: '商品B', quantity: 1, unit_price: 1500, amount: 1500)

      invoice.reload
      initial_total = invoice.total_amount

      # 明細を削除
      item1.destroy

      invoice.reload

      # 合計が更新されている
      expect(invoice.total_amount).to be < initial_total
      expect(invoice.subtotal).to eq(1500)
    end
  end
end
