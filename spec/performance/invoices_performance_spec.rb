require 'rails_helper'

RSpec.describe "InvoicesPerformance", type: :request do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') }
  let!(:companies) do
    10.times.map do |i|
      Company.create!(
        name: "テスト企業#{i}",
        formal_name: "テスト企業株式会社#{i}",
        contract_status: 'active',
        billing_email: "company#{i}@example.com"
      )
    end
  end

  before do
    sign_in admin_user
  end

  describe "請求書一覧のパフォーマンス" do
    before do
      # 100件の請求書を作成
      companies.each do |company|
        10.times do |i|
          Invoice.create!(
            company: company,
            invoice_number: "INV-#{company.id}-#{i.to_s.rjust(4, '0')}",
            issue_date: Date.today - (i * 30).days,
            payment_due_date: Date.today - (i * 30).days + 30.days,
            billing_period_start: Date.today - (i * 30).days - 30.days,
            billing_period_end: Date.today - (i * 30).days,
            subtotal: 10000 * (i + 1),
            tax_amount: 1000 * (i + 1),
            total_amount: 11000 * (i + 1),
            status: ['draft', 'sent', 'paid'].sample,
            payment_status: ['unpaid', 'partial', 'paid'].sample
          )
        end
      end
    end

    it "100件の請求書一覧が1秒以内に表示される" do
      start_time = Time.current
      get admin_invoices_path
      end_time = Time.current

      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 1.0
    end

    it "N+1クエリが発生しない" do
      # Bulletが有効な場合、N+1クエリがあると例外が発生
      expect { get admin_invoices_path }.not_to raise_error
    end
  end

  describe "請求書PDF生成のパフォーマンス" do
    let(:company) { companies.first }
    let!(:invoice) do
      Invoice.create!(
        company: company,
        invoice_number: 'INV-PERF-0001',
        issue_date: Date.today,
        payment_due_date: Date.today + 30.days,
        billing_period_start: Date.today - 30.days,
        billing_period_end: Date.today,
        subtotal: 100000,
        tax_amount: 10000,
        total_amount: 110000,
        status: 'sent',
        payment_status: 'unpaid'
      )
    end

    before do
      # 10件の明細を追加
      10.times do |i|
        InvoiceItem.create!(
          invoice: invoice,
          description: "サービス#{i + 1}",
          quantity: rand(1..10),
          unit_price: 1000 * (i + 1),
          amount: 1000 * (i + 1) * rand(1..10)
        )
      end
    end

    it "PDF生成が3秒以内に完了する" do
      start_time = Time.current
      pdf = InvoicePdfGenerator.new(invoice).generate
      end_time = Time.current

      expect(pdf).to be_present
      expect(end_time - start_time).to be < 3.0
    end
  end

  describe "大量請求書生成のパフォーマンス" do
    let!(:restaurant) do
      Restaurant.create!(
        name: 'テスト飲食店',
        contract_status: 'active',
        max_capacity: 1000
      )
    end
    let!(:menu) { Menu.create!(name: 'テストメニュー', restaurant: restaurant) }
    let!(:orders) do
      companies.first(5).flat_map do |company|
        20.times.map do |i|
          order = Order.new(
            company: company,
            restaurant: restaurant,
            menu: menu,
            order_type: 'recurring',
            scheduled_date: Date.today - (i * 7).days,
            default_meal_count: rand(10..50),
            status: 'completed'
          )
          order.save(validate: false)
          order
        end
      end
    end

    it "100件の案件から5件の請求書を5秒以内に生成できる" do
      start_time = Time.current
      generator = InvoiceGenerator.new

      companies.first(5).each do |company|
        # 今月の請求書を生成
        generator.generate_monthly_invoice(company.id, Date.today.year, Date.today.month)
      end

      end_time = Time.current

      expect(end_time - start_time).to be < 5.0
      expect(Invoice.count).to be >= 5
    end
  end
end
