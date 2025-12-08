require 'rails_helper'

RSpec.describe GenerateInvoicesJob, type: :job do
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

  describe '#perform' do
    before do
      # 2025年12月の案件を作成（水曜日）
      base_date = Date.new(2025, 12, 1)
      wednesday = base_date.beginning_of_month
      wednesday += 1.day until wednesday.wday == 3

      create_order_with_items(
        company: company,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday,
        meal_count: 20,
        status: 'completed'
      )
    end

    it '請求書が生成される' do
      result = GenerateInvoicesJob.new.perform(2025, 12)

      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:invoice_ids]).to be_present
      expect(Invoice.count).to eq(1)
    end

    it '指定企業のみの請求書が生成される' do
      company2 = Company.create!(name: 'テスト企業2', formal_name: 'テスト企業2株式会社', contract_status: 'active')

      base_date = Date.new(2025, 12, 1)
      wednesday = base_date.beginning_of_month
      wednesday += 1.day until wednesday.wday == 3

      create_order_with_items(
        company: company2,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday,
        meal_count: 15,
        status: 'completed'
      )

      result = GenerateInvoicesJob.new.perform(2025, 12, company_ids: [company.id])

      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)

      invoice = Invoice.last
      expect(invoice.company).to eq(company)
    end

    it '案件がない場合、請求書は生成されない' do
      # 2025年1月（案件がない月）で実行
      result = GenerateInvoicesJob.new.perform(2025, 1)

      expect(result[:success]).to be false
      expect(result[:count]).to eq(0)
      expect(result[:errors]).to be_present
    end
  end
end
