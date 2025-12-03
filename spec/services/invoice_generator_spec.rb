require 'rails_helper'

RSpec.describe InvoiceGenerator do
  let(:generator) { InvoiceGenerator.new }
  let(:company) { Company.create!(name: 'テスト企業', formal_name: 'テスト企業株式会社', contract_status: 'active') }
  let(:restaurant) do
    Restaurant.create!(
      name: 'テスト飲食店',
      contract_status: 'active',
      max_capacity: 100,
      capacity_per_day: 50
    )
  end
  let(:menu) { Menu.create!(name: 'テストメニュー', restaurant: restaurant, price_per_meal: 800) }

  describe '#generate_monthly_invoice' do
    context '案件が存在する場合' do
      before do
        # 2025年12月の案件を3件作成（closed_daysを避けて水曜日に設定）
        base_date = Date.new(2025, 12, 1)
        # 最初の水曜日を見つける
        wednesday = base_date.beginning_of_month
        wednesday += 1.day until wednesday.wday == 3 # 水曜日

        3.times do |i|
          Order.create!(
            company: company,
            restaurant: restaurant,
            menu: menu,
            order_type: 'trial',
            scheduled_date: wednesday + (i * 7).days,
            default_meal_count: 20 + (i * 5),
            status: 'completed'
          )
        end
      end

      it '請求書が生成される' do
        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        expect(invoice).to be_present
        expect(invoice).to be_persisted
        expect(invoice.company).to eq(company)
        expect(invoice.billing_period_start).to eq(Date.new(2025, 12, 1))
        expect(invoice.billing_period_end).to eq(Date.new(2025, 12, 31))
      end

      it '請求明細が作成される' do
        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        expect(invoice.invoice_items.count).to eq(3)
        expect(invoice.invoice_items.first.description).to include('テスト飲食店')
        expect(invoice.invoice_items.first.description).to include('テストメニュー')
      end

      it '金額が正しく計算される' do
        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        # 20 * 800 + 25 * 800 + 30 * 800 = 16,000 + 20,000 + 24,000 = 60,000
        expect(invoice.subtotal).to eq(60_000)
        expect(invoice.tax_amount).to eq(6_000)
        expect(invoice.total_amount).to eq(66_000)
      end

      it '請求書番号が自動生成される' do
        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        expect(invoice.invoice_number).to match(/^INV-\d{6}-\d{4}$/)
      end
    end

    context '割引が設定されている場合' do
      it '固定額割引が適用される' do
        company.update!(discount_type: 'fixed', discount_amount: 5000)

        base_date = Date.new(2025, 12, 1)
        wednesday = base_date.beginning_of_month
        wednesday += 1.day until wednesday.wday == 3

        Order.create!(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: wednesday,
          default_meal_count: 20,
          status: 'completed'
        )

        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        # 20 * 800 = 16,000 - 5,000 = 11,000
        expect(invoice.subtotal).to eq(11_000)
        expect(invoice.tax_amount).to eq(1_100)
        expect(invoice.total_amount).to eq(12_100)
      end

      it 'パーセント割引が適用される' do
        company.update!(discount_type: 'percentage', discount_amount: 10)

        base_date = Date.new(2025, 12, 1)
        wednesday = base_date.beginning_of_month
        wednesday += 1.day until wednesday.wday == 3

        Order.create!(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: wednesday,
          default_meal_count: 20,
          status: 'completed'
        )

        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        # 20 * 800 = 16,000 * 0.9 = 14,400
        expect(invoice.subtotal).to eq(14_400)
        expect(invoice.tax_amount).to eq(1_440)
        expect(invoice.total_amount).to eq(15_840)
      end
    end

    context '案件が存在しない場合' do
      it 'nilを返す' do
        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        expect(invoice).to be_nil
        expect(generator.errors).to include(match(/No orders found/))
      end
    end

    context '既存の請求書がある場合' do
      before do
        base_date = Date.new(2025, 12, 1)
        wednesday = base_date.beginning_of_month
        wednesday += 1.day until wednesday.wday == 3

        Order.create!(
          company: company,
          restaurant: restaurant,
          menu: menu,
          order_type: 'trial',
          scheduled_date: wednesday,
          default_meal_count: 20,
          status: 'completed'
        )

        # 既存の請求書を作成
        Invoice.create!(
          company: company,
          issue_date: Date.new(2025, 12, 1),
          payment_due_date: Date.new(2025, 12, 31),
          billing_period_start: Date.new(2025, 12, 1),
          billing_period_end: Date.new(2025, 12, 31),
          total_amount: 10000
        )
      end

      it '既存の請求書を返す' do
        invoice = generator.generate_monthly_invoice(company.id, 2025, 12)

        expect(invoice).to be_present
        expect(generator.errors).to include(match(/Invoice already exists/))
      end
    end

    context '企業が存在しない場合' do
      it 'nilを返す' do
        invoice = generator.generate_monthly_invoice(99999, 2025, 12)

        expect(invoice).to be_nil
        expect(generator.errors).to include(match(/Company.*not found/))
      end
    end
  end

  describe '#generate_all_monthly_invoices' do
    let(:company2) { Company.create!(name: 'テスト企業2', formal_name: 'テスト企業2株式会社', contract_status: 'active') }

    before do
      base_date = Date.new(2025, 12, 1)
      wednesday = base_date.beginning_of_month
      wednesday += 1.day until wednesday.wday == 3

      # 企業1の案件
      Order.create!(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday,
        default_meal_count: 20,
        status: 'completed'
      )

      # 企業2の案件
      Order.create!(
        company: company2,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday,
        default_meal_count: 15,
        status: 'completed'
      )
    end

    it '全企業の請求書が生成される' do
      invoices = generator.generate_all_monthly_invoices(2025, 12)

      expect(invoices.count).to eq(2)
      expect(invoices.map(&:company)).to match_array([company, company2])
    end

    it '指定企業のみの請求書が生成される' do
      invoices = generator.generate_all_monthly_invoices(2025, 12, company_ids: [company.id])

      expect(invoices.count).to eq(1)
      expect(invoices.first.company).to eq(company)
    end
  end
end
