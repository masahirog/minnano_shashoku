class ReportGeneratorService
  attr_reader :year, :month, :billing_period_start, :billing_period_end

  def initialize(year: Date.today.year, month: Date.today.month)
    @year = year
    @month = month
    @billing_period_start = Date.new(year, month, 1)
    @billing_period_end = @billing_period_start.end_of_month
  end

  # 月次支払状況レポートを生成
  def generate_monthly_payment_report
    {
      period: {
        year: @year,
        month: @month,
        start_date: @billing_period_start,
        end_date: @billing_period_end
      },
      summary: payment_summary,
      by_status: invoices_by_payment_status,
      by_company: payment_by_company,
      overdue: overdue_invoices_data,
      recent_payments: recent_payments_data
    }
  end

  # 支払状況サマリー
  def payment_summary
    invoices = Invoice.includes(:payments).where(billing_period_start: @billing_period_start)

    total_amount = invoices.sum(:total_amount)
    paid_amount = invoices.map(&:paid_amount).sum
    unpaid_amount = total_amount - paid_amount

    {
      total_invoices: invoices.count,
      total_amount: total_amount,
      paid_amount: paid_amount,
      unpaid_amount: unpaid_amount,
      payment_rate: total_amount > 0 ? (paid_amount.to_f / total_amount * 100).round(2) : 0
    }
  end

  # 支払ステータス別の請求書データ
  def invoices_by_payment_status
    invoices = Invoice.where(billing_period_start: @billing_period_start)
    partial_invoices = invoices.includes(:payments).where(payment_status: 'partial')

    {
      paid: {
        count: invoices.where(payment_status: 'paid').count,
        amount: invoices.where(payment_status: 'paid').sum(:total_amount)
      },
      partial: {
        count: partial_invoices.count,
        amount: partial_invoices.sum(:total_amount),
        paid: partial_invoices.map(&:paid_amount).sum
      },
      unpaid: {
        count: invoices.where(payment_status: 'unpaid').count,
        amount: invoices.where(payment_status: 'unpaid').sum(:total_amount)
      },
      overdue: {
        count: invoices.where(payment_status: 'overdue').count,
        amount: invoices.where(payment_status: 'overdue').sum(:total_amount)
      }
    }
  end

  # 企業別の支払状況
  def payment_by_company
    companies_data = Invoice.includes(:company, :payments)
                            .where(billing_period_start: @billing_period_start)
                            .group_by(&:company)
                            .map do |company, invoices|
      total_amount = invoices.sum(&:total_amount)
      paid_amount = invoices.sum(&:paid_amount)

      {
        company_id: company.id,
        company_name: company.name,
        invoice_count: invoices.count,
        total_amount: total_amount,
        paid_amount: paid_amount,
        unpaid_amount: total_amount - paid_amount
      }
    end

    companies_data.sort_by { |c| -c[:total_amount] }
  end

  # 期限超過請求書データ
  def overdue_invoices_data
    invoices = Invoice.includes(:company, :payments)
                      .where(payment_status: ['unpaid', 'partial', 'overdue'])
                      .where('payment_due_date < ?', Date.today)
                      .order(:payment_due_date)

    invoices_list = invoices.map do |invoice|
      {
        id: invoice.id,
        invoice_number: invoice.invoice_number,
        company_name: invoice.company.name,
        payment_due_date: invoice.payment_due_date,
        total_amount: invoice.total_amount,
        paid_amount: invoice.paid_amount,
        remaining_balance: invoice.remaining_balance,
        days_overdue: invoice.days_overdue
      }
    end

    {
      count: invoices.count,
      total_amount: invoices.sum(:total_amount),
      total_unpaid: invoices.map(&:remaining_balance).sum,
      invoices: invoices_list
    }
  end

  # 最近の入金データ
  def recent_payments_data(limit: 10)
    payments = Payment.includes(invoice: :company)
                      .where('payment_date >= ? AND payment_date <= ?', @billing_period_start, @billing_period_end)
                      .order(payment_date: :desc)
                      .limit(limit)

    {
      count: payments.count,
      total_amount: payments.sum(:amount),
      payments: payments.map do |payment|
        {
          id: payment.id,
          payment_date: payment.payment_date,
          amount: payment.amount,
          payment_method: payment.payment_method,
          invoice_number: payment.invoice.invoice_number,
          company_name: payment.invoice.company.name,
          reference_number: payment.reference_number
        }
      end
    }
  end

  # グラフ用データ: 支払ステータス別の金額
  def chart_data_by_status
    data = invoices_by_payment_status

    {
      labels: ['支払済み', '一部支払', '未払い', '期限超過'],
      datasets: [{
        label: '金額 (円)',
        data: [
          data[:paid][:amount],
          data[:partial][:amount],
          data[:unpaid][:amount],
          data[:overdue][:amount]
        ],
        backgroundColor: [
          '#4CAF50',  # 緑 - 支払済み
          '#FF9800',  # オレンジ - 一部支払
          '#2196F3',  # 青 - 未払い
          '#F44336'   # 赤 - 期限超過
        ]
      }]
    }
  end

  # グラフ用データ: 企業別の支払状況
  def chart_data_by_company(top_n: 10)
    companies = payment_by_company.sort_by { |c| -c[:total_amount] }.take(top_n)

    {
      labels: companies.map { |c| c[:company_name] },
      datasets: [
        {
          label: '支払済み (円)',
          data: companies.map { |c| c[:paid_amount] },
          backgroundColor: '#4CAF50'
        },
        {
          label: '未払い (円)',
          data: companies.map { |c| c[:unpaid_amount] },
          backgroundColor: '#F44336'
        }
      ]
    }
  end
end
