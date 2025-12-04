require 'rails_helper'

RSpec.describe 'Admin::Invoices', type: :request do
  let(:admin_user) { create(:admin_user) }

  let(:company) do
    Company.create!(
      name: 'テスト企業',
      formal_name: 'テスト企業株式会社',
      contract_status: 'active'
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
      invoice_number: 'INV-202512-0001'
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

  before do
    sign_in admin_user
  end

  describe 'GET /admin/invoice_pdfs/:id' do
    context '請求書が存在する場合' do
      before do
        invoice_item # 請求明細を作成
      end

      it 'PDFが正常に生成される' do
        get admin_invoice_pdf_path(invoice)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('application/pdf')
        expect(response.headers['Content-Disposition']).to include('inline')
        expect(response.body).to start_with('%PDF-')
      end

      it 'ファイル名が正しく設定される' do
        get admin_invoice_pdf_path(invoice)

        filename = "invoice_#{invoice.invoice_number}_#{Date.today.strftime('%Y%m%d')}.pdf"
        expect(response.headers['Content-Disposition']).to include(filename)
      end
    end

    context '請求書が存在しない場合' do
      it '404エラーでリダイレクトされる' do
        get admin_invoice_pdf_path(id: 99999)

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to eq('請求書が見つかりませんでした。')
      end
    end

    context 'PDF生成でエラーが発生する場合' do
      before do
        invoice_item
        allow(InvoicePdfGenerator).to receive(:new).and_raise(StandardError.new('PDF生成失敗'))
      end

      it 'エラーメッセージとともにリダイレクトされる' do
        get admin_invoice_pdf_path(invoice)

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to eq('PDF生成中にエラーが発生しました。')
      end
    end
  end

  describe 'POST /admin/invoice_generations' do
    let(:company2) do
      Company.create!(
        name: 'テスト企業2',
        formal_name: 'テスト企業2株式会社',
        contract_status: 'active'
      )
    end

    before do
      # 2025年12月の案件を作成
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

      Order.create!(
        company: company2,
        restaurant: restaurant,
        menu: menu,
        order_type: 'trial',
        scheduled_date: wednesday + 7.days,
        default_meal_count: 15,
        status: 'completed'
      )
    end

    context '有効なパラメータの場合' do
      it '請求書が生成される' do
        expect {
          post admin_invoice_generations_path, params: { year: 2025, month: 12 }
        }.to change { Invoice.count }.by(2)

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:notice]).to eq('2025年12月の請求書を2件生成しました。')
      end

      it '生成された請求書の内容が正しい' do
        post admin_invoice_generations_path, params: { year: 2025, month: 12 }

        invoice1 = Invoice.find_by(company: company, billing_period_start: Date.new(2025, 12, 1))
        expect(invoice1).to be_present
        expect(invoice1.billing_period_end).to eq(Date.new(2025, 12, 31))
        expect(invoice1.invoice_items.count).to eq(1)
      end
    end

    context '特定企業のみ指定する場合' do
      it '指定した企業のみ請求書が生成される' do
        expect {
          post admin_invoice_generations_path, params: {
            year: 2025,
            month: 12,
            company_ids: [company.id]
          }
        }.to change { Invoice.count }.by(1)

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:notice]).to eq('2025年12月の請求書を1件生成しました。')

        expect(Invoice.find_by(company: company)).to be_present
        expect(Invoice.find_by(company: company2)).to be_nil
      end
    end

    context '対象案件がない場合' do
      it 'エラーメッセージが表示される' do
        post admin_invoice_generations_path, params: { year: 2026, month: 1 }

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to eq('2026年1月の対象となる案件が見つかりませんでした。')
      end
    end

    context '既に請求書が存在する場合' do
      before do
        # 既存の請求書を作成
        Invoice.create!(
          company: company,
          issue_date: Date.new(2025, 12, 31),
          payment_due_date: Date.new(2026, 1, 31),
          billing_period_start: Date.new(2025, 12, 1),
          billing_period_end: Date.new(2025, 12, 31),
          subtotal: 16_000,
          tax_amount: 1_600,
          total_amount: 17_600
        )
      end

      it '既存の請求書をスキップして警告メッセージが表示される' do
        expect {
          post admin_invoice_generations_path, params: { year: 2025, month: 12 }
        }.to change { Invoice.count }.by(1) # company2のみ生成される

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to include('一部の企業で請求書を生成できませんでした')
      end
    end

    context '無効な年が指定された場合' do
      it 'エラーメッセージが表示される' do
        post admin_invoice_generations_path, params: { year: 1999, month: 12 }

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to eq('有効な年を指定してください。')
      end

      it '請求書は生成されない' do
        expect {
          post admin_invoice_generations_path, params: { year: 2101, month: 12 }
        }.not_to change { Invoice.count }
      end
    end

    context '無効な月が指定された場合' do
      it 'エラーメッセージが表示される（月が0）' do
        post admin_invoice_generations_path, params: { year: 2025, month: 0 }

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to eq('有効な月を指定してください。')
      end

      it 'エラーメッセージが表示される（月が13）' do
        post admin_invoice_generations_path, params: { year: 2025, month: 13 }

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to eq('有効な月を指定してください。')
      end

      it '請求書は生成されない' do
        expect {
          post admin_invoice_generations_path, params: { year: 2025, month: 0 }
        }.not_to change { Invoice.count }
      end
    end

    context 'InvoiceGeneratorでエラーが発生する場合' do
      before do
        allow_any_instance_of(InvoiceGenerator).to receive(:generate_all_monthly_invoices)
          .and_raise(StandardError.new('予期しないエラー'))
      end

      it 'エラーメッセージが表示される' do
        post admin_invoice_generations_path, params: { year: 2025, month: 12 }

        expect(response).to redirect_to(admin_invoices_path)
        expect(flash[:alert]).to eq('請求書生成中にエラーが発生しました。')
      end
    end
  end
end
