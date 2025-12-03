require 'rails_helper'

RSpec.describe InvoicePdfGenerator do
  let(:company) do
    Company.create!(
      name: 'テスト企業',
      formal_name: 'テスト企業株式会社',
      contract_status: 'active',
      delivery_address: '東京都渋谷区テスト町1-2-3',
      contact_person: '山田太郎'
    )
  end

  let(:restaurant) do
    Restaurant.create!(
      name: 'テスト飲食店',
      contract_status: 'active',
      max_capacity: 100,
      capacity_per_day: 50
    )
  end

  let(:menu) do
    Menu.create!(
      name: 'テストメニュー',
      restaurant: restaurant,
      price_per_meal: 800
    )
  end

  let(:order) do
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.new(2025, 12, 15),
      default_meal_count: 20,
      status: 'completed'
    )
  end

  let(:invoice) do
    Invoice.create!(
      company: company,
      issue_date: Date.new(2025, 12, 31),
      payment_due_date: Date.new(2026, 1, 31),
      billing_period_start: Date.new(2025, 12, 1),
      billing_period_end: Date.new(2025, 12, 31),
      subtotal: 16_000,
      tax_amount: 1_600,
      total_amount: 17_600,
      invoice_number: 'INV-202512-0001',
      notes: 'テスト備考'
    )
  end

  let(:invoice_item) do
    InvoiceItem.create!(
      invoice: invoice,
      order: order,
      description: '2025/12/15 テスト飲食店 - テストメニュー',
      quantity: 20,
      unit_price: 800,
      amount: 16_000
    )
  end

  describe '#generate' do
    let(:generator) { InvoicePdfGenerator.new(invoice) }

    before do
      invoice_item # 事前にinvoice_itemを作成
    end

    it 'PDFデータが生成される' do
      pdf_data = generator.generate

      expect(pdf_data).to be_present
      expect(pdf_data).to be_a(String)
      expect(pdf_data.length).to be > 0
    end

    it '生成されたデータがPDF形式である' do
      pdf_data = generator.generate

      # PDFファイルは"%PDF-"で始まる
      expect(pdf_data[0..4]).to eq('%PDF-')
    end

    it 'PDFサイズが妥当である' do
      pdf_data = generator.generate

      # 日本語フォント埋め込みありのPDFは最低でも数KB以上
      expect(pdf_data.length).to be > 5000
    end

    context '複数の請求明細がある場合' do
      let(:order2) do
        Order.create!(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'regular',
          scheduled_date: Date.new(2025, 12, 20),
          default_meal_count: 30,
          status: 'completed'
        )
      end

      let(:invoice_item2) do
        InvoiceItem.create!(
          invoice: invoice,
          order: order2,
          description: '2025/12/20 テスト飲食店 - テストメニュー',
          quantity: 30,
          unit_price: 800,
          amount: 24_000
        )
      end

      before do
        invoice_item2
        invoice.update!(
          subtotal: 40_000,
          tax_amount: 4_000,
          total_amount: 44_000
        )
      end

      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
        expect(pdf_data.length).to be > 5000
      end
    end

    context '備考がない場合' do
      before do
        invoice.update!(notes: nil)
      end

      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
      end
    end

    context '備考がある場合' do
      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
      end
    end

    context '企業の配送先住所がない場合' do
      before do
        company.update!(delivery_address: nil)
      end

      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
      end
    end

    context '企業の担当者名がない場合' do
      before do
        company.update!(contact_person: nil)
      end

      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
      end
    end

    context '大きな金額の場合' do
      before do
        invoice.update!(
          subtotal: 10_000_000,
          tax_amount: 1_000_000,
          total_amount: 11_000_000
        )
      end

      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
      end
    end

    context 'Orderが関連付けられていないInvoiceItemの場合' do
      let(:manual_invoice_item) do
        InvoiceItem.create!(
          invoice: invoice,
          order: nil,
          description: '手動追加項目',
          quantity: 1,
          unit_price: 5_000,
          amount: 5_000
        )
      end

      before do
        manual_invoice_item
      end

      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
      end
    end

    context 'InvoiceItemが多数ある場合' do
      before do
        # 20個の明細を追加
        20.times do |i|
          InvoiceItem.create!(
            invoice: invoice,
            order: nil,
            description: "項目#{i + 1}",
            quantity: 1,
            unit_price: 1000,
            amount: 1000
          )
        end
      end

      it 'PDFが正常に生成される' do
        pdf_data = generator.generate

        expect(pdf_data).to be_present
        expect(pdf_data[0..4]).to eq('%PDF-')
      end
    end
  end

  describe '#number_with_delimiter (private method)' do
    let(:generator) { InvoicePdfGenerator.new(invoice) }

    it '3桁ごとにカンマが挿入される' do
      result = generator.send(:number_with_delimiter, 1234567)
      expect(result).to eq('1,234,567')
    end

    it '1000未満の数値はカンマなし' do
      result = generator.send(:number_with_delimiter, 999)
      expect(result).to eq('999')
    end

    it '1000はカンマ付き' do
      result = generator.send(:number_with_delimiter, 1000)
      expect(result).to eq('1,000')
    end

    it '0の場合' do
      result = generator.send(:number_with_delimiter, 0)
      expect(result).to eq('0')
    end

    it '負の数値の場合' do
      result = generator.send(:number_with_delimiter, -12345)
      expect(result).to eq('-12,345')
    end

    it '小数点を含む数値の場合' do
      result = generator.send(:number_with_delimiter, 1234.56)
      expect(result).to eq('1,234.56')
    end
  end
end
