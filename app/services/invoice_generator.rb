class InvoiceGenerator
  attr_reader :errors

  def initialize
    @errors = []
  end

  # 指定企業の月次請求書を生成
  # @param company_id [Integer] 企業ID
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @return [Invoice, nil] 生成された請求書、またはnil（エラー時）
  def generate_monthly_invoice(company_id, year, month)
    @errors = []

    company = Company.find_by(id: company_id)
    unless company
      @errors << "Company with ID #{company_id} not found"
      return nil
    end

    # 請求期間を設定
    billing_period_start = Date.new(year, month, 1)
    billing_period_end = billing_period_start.end_of_month

    # 対象期間の案件を取得（完了または確定済みのみ）
    orders = Order.where(company: company)
                  .where(scheduled_date: billing_period_start..billing_period_end)
                  .where(status: ['completed', 'confirmed'])
                  .includes(:menu, :restaurant)

    if orders.empty?
      @errors << "No orders found for #{company.name} in #{year}/#{month}"
      return nil
    end

    # 既存の請求書がある場合はスキップ
    existing_invoice = Invoice.where(
      company: company,
      billing_period_start: billing_period_start,
      billing_period_end: billing_period_end
    ).first

    if existing_invoice
      @errors << "Invoice already exists for #{company.name} in #{year}/#{month}: #{existing_invoice.invoice_number}"
      return existing_invoice
    end

    # トランザクション内で請求書と明細を作成
    invoice = nil
    ActiveRecord::Base.transaction do
      # 請求書を作成
      invoice = Invoice.new(
        company: company,
        issue_date: Date.today,
        payment_due_date: Date.today + 30.days,
        billing_period_start: billing_period_start,
        billing_period_end: billing_period_end,
        subtotal: 0,
        tax_amount: 0,
        total_amount: 0,
        status: 'draft',
        payment_status: 'unpaid'
      )

      # 明細を作成
      orders.each do |order|
        menu = order.menu
        next unless menu&.price_per_meal

        meal_count = order.confirmed_meal_count || order.default_meal_count
        unit_price = menu.price_per_meal

        description = "#{order.scheduled_date.strftime('%Y/%m/%d')} - #{order.restaurant&.name} - #{menu.name}"

        invoice.invoice_items.build(
          order: order,
          description: description,
          quantity: meal_count,
          unit_price: unit_price,
          amount: meal_count * unit_price
        )
      end

      # 小計を計算
      invoice.calculate_subtotal

      # 割引を適用（割引明細を追加）
      if company.discount_type.present? && company.discount_amount.present?
        add_discount_item(invoice, company)
        # 割引後の小計を再計算
        invoice.calculate_subtotal
      end

      # 消費税と合計を計算
      invoice.calculate_tax
      invoice.calculate_total

      # 保存
      invoice.save!
    end

    invoice
  rescue StandardError => e
    @errors << "Error generating invoice: #{e.message}"
    nil
  end

  # 全企業の月次請求書を一括生成
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @param company_ids [Array<Integer>, nil] 対象企業ID配列（nilの場合は全企業）
  # @return [Array<Invoice>] 生成された請求書の配列
  def generate_all_monthly_invoices(year, month, company_ids: nil)
    @errors = []
    invoices = []

    # 対象企業を取得
    companies = if company_ids.present?
                  Company.where(id: company_ids, contract_status: 'active')
                else
                  Company.where(contract_status: 'active')
                end

    companies.find_each do |company|
      invoice = generate_monthly_invoice(company.id, year, month)
      invoices << invoice if invoice
    end

    invoices
  end

  private

  # 割引明細を追加
  def add_discount_item(invoice, company)
    discount_amount = case company.discount_type
                      when 'fixed'
                        # 固定額割引
                        -company.discount_amount
                      when 'percentage'
                        # パーセント割引
                        -(invoice.subtotal * company.discount_amount / 100.0).round
                      else
                        0
                      end

    return if discount_amount == 0

    # 割引明細を追加
    invoice.invoice_items.build(
      description: "割引 (#{company.discount_type == 'fixed' ? '固定額' : "#{company.discount_amount}%"})",
      quantity: 1,
      unit_price: discount_amount,
      amount: discount_amount
    )
  end
end
