require 'prawn'
require 'prawn/table'

class ReportPdfGenerator
  def initialize(report_data)
    @report_data = report_data
    @pdf = Prawn::Document.new(page_size: 'A4', margin: 40)
    setup_fonts
  end

  def generate
    draw_header
    draw_summary
    draw_status_breakdown
    draw_overdue_invoices if @report_data[:overdue][:count] > 0
    draw_company_breakdown
    draw_recent_payments
    draw_footer
    @pdf
  end

  private

  def setup_fonts
    font_path = Rails.root.join('app', 'assets', 'fonts')
    regular_font = font_path.join('NotoSansJP-Regular.ttf')
    bold_font = font_path.join('NotoSansJP-Bold.ttf')

    if File.exist?(regular_font) && File.exist?(bold_font)
      # 両方のフォントが存在する場合
      @pdf.font_families.update(
        'NotoSansJP' => {
          normal: regular_font.to_s,
          bold: bold_font.to_s
        }
      )
      @pdf.font 'NotoSansJP'
      @use_japanese_font = true
      @has_bold_font = true
    elsif File.exist?(regular_font)
      # Regularフォントのみ存在する場合
      @pdf.font_families.update(
        'NotoSansJP' => {
          normal: regular_font.to_s,
          bold: regular_font.to_s # boldもRegularを使用
        }
      )
      @pdf.font 'NotoSansJP'
      @use_japanese_font = true
      @has_bold_font = false
    else
      # フォントが見つからない場合はデフォルトフォントを使用
      @pdf.font 'Helvetica'
      @use_japanese_font = false
      @has_bold_font = true # Helveticaはboldをサポート
    end
  end

  def draw_header
    @pdf.text '月次支払状況レポート', size: 20, style: :bold, align: :center
    @pdf.move_down 10
    @pdf.text "対象期間: #{@report_data[:period][:year]}年#{@report_data[:period][:month]}月",
              size: 14, align: :center
    @pdf.move_down 20
  end

  def draw_summary
    @pdf.text 'サマリー', size: 16, style: :bold
    @pdf.move_down 10

    summary_data = [
      ['項目', '値'],
      ['総請求書数', "#{@report_data[:summary][:total_invoices]} 件"],
      ['総請求額', "¥#{format_currency(@report_data[:summary][:total_amount])}"],
      ['支払済み額', "¥#{format_currency(@report_data[:summary][:paid_amount])}"],
      ['未払い額', "¥#{format_currency(@report_data[:summary][:unpaid_amount])}"],
      ['支払率', "#{@report_data[:summary][:payment_rate]}%"]
    ]

    @pdf.table(summary_data,
               header: true,
               width: @pdf.bounds.width,
               cell_style: { size: 10, padding: 8 },
               row_colors: ['F5F5F5', 'FFFFFF']) do
      row(0).font_style = :bold
      row(0).background_color = 'DDDDDD'
    end

    @pdf.move_down 20
  end

  def draw_status_breakdown
    @pdf.text '支払ステータス別集計', size: 16, style: :bold
    @pdf.move_down 10

    status_data = [
      ['ステータス', '件数', '金額', '割合'],
      [
        '支払済み',
        "#{@report_data[:by_status][:paid][:count]} 件",
        "¥#{format_currency(@report_data[:by_status][:paid][:amount])}",
        "#{calculate_percentage(@report_data[:by_status][:paid][:amount])}%"
      ],
      [
        '一部支払',
        "#{@report_data[:by_status][:partial][:count]} 件",
        "¥#{format_currency(@report_data[:by_status][:partial][:amount])}",
        "#{calculate_percentage(@report_data[:by_status][:partial][:amount])}%"
      ],
      [
        '未払い',
        "#{@report_data[:by_status][:unpaid][:count]} 件",
        "¥#{format_currency(@report_data[:by_status][:unpaid][:amount])}",
        "#{calculate_percentage(@report_data[:by_status][:unpaid][:amount])}%"
      ],
      [
        '期限超過',
        "#{@report_data[:by_status][:overdue][:count]} 件",
        "¥#{format_currency(@report_data[:by_status][:overdue][:amount])}",
        "#{calculate_percentage(@report_data[:by_status][:overdue][:amount])}%"
      ]
    ]

    @pdf.table(status_data,
               header: true,
               width: @pdf.bounds.width,
               cell_style: { size: 10, padding: 8 },
               row_colors: ['F5F5F5', 'FFFFFF']) do
      row(0).font_style = :bold
      row(0).background_color = 'DDDDDD'
      columns(1..3).align = :right
    end

    @pdf.move_down 20
  end

  def draw_overdue_invoices
    @pdf.text "期限超過請求書（#{@report_data[:overdue][:count]}件）", size: 16, style: :bold
    @pdf.move_down 10

    overdue_data = [['請求書番号', '企業名', '支払期限', '残高', '超過日数']]

    @report_data[:overdue][:invoices].take(10).each do |invoice|
      overdue_data << [
        invoice[:invoice_number],
        invoice[:company_name].to_s.slice(0, 20),
        invoice[:payment_due_date].strftime('%Y/%m/%d'),
        "¥#{format_currency(invoice[:remaining_balance])}",
        "#{invoice[:days_overdue]}日"
      ]
    end

    @pdf.table(overdue_data,
               header: true,
               width: @pdf.bounds.width,
               cell_style: { size: 9, padding: 6 },
               row_colors: ['F5F5F5', 'FFFFFF']) do
      row(0).font_style = :bold
      row(0).background_color = 'FFDDDD'
      columns(2..4).align = :right
    end

    if @report_data[:overdue][:invoices].count > 10
      @pdf.move_down 5
      @pdf.text "※ 上位10件のみ表示（全#{@report_data[:overdue][:invoices].count}件）", size: 8
    end

    @pdf.move_down 20
  end

  def draw_company_breakdown
    @pdf.start_new_page if @pdf.cursor < 300

    @pdf.text '企業別支払状況（上位10社）', size: 16, style: :bold
    @pdf.move_down 10

    company_data = [['企業名', '請求書数', '総請求額', '支払済み', '未払い', '支払率']]

    @report_data[:by_company].sort_by { |c| -c[:total_amount] }.take(10).each do |company|
      payment_rate = company[:total_amount] > 0 ?
        ((company[:paid_amount].to_f / company[:total_amount] * 100).round(1)) : 0

      company_data << [
        company[:company_name].to_s.slice(0, 15),
        "#{company[:invoice_count]}件",
        "¥#{format_currency(company[:total_amount])}",
        "¥#{format_currency(company[:paid_amount])}",
        "¥#{format_currency(company[:unpaid_amount])}",
        "#{payment_rate}%"
      ]
    end

    @pdf.table(company_data,
               header: true,
               width: @pdf.bounds.width,
               cell_style: { size: 9, padding: 6 },
               row_colors: ['F5F5F5', 'FFFFFF']) do
      row(0).font_style = :bold
      row(0).background_color = 'DDDDDD'
      columns(1..5).align = :right
    end

    @pdf.move_down 20
  end

  def draw_recent_payments
    @pdf.start_new_page if @pdf.cursor < 250

    @pdf.text "最近の入金（#{@report_data[:recent_payments][:count]}件）", size: 16, style: :bold
    @pdf.move_down 10

    payment_data = [['入金日', '企業名', '請求書番号', '入金額', '支払方法']]

    @report_data[:recent_payments][:payments].take(10).each do |payment|
      payment_data << [
        payment[:payment_date].strftime('%Y/%m/%d'),
        payment[:company_name].to_s.slice(0, 15),
        payment[:invoice_number],
        "¥#{format_currency(payment[:amount])}",
        payment[:payment_method] || '-'
      ]
    end

    @pdf.table(payment_data,
               header: true,
               width: @pdf.bounds.width,
               cell_style: { size: 9, padding: 6 },
               row_colors: ['F5F5F5', 'FFFFFF']) do
      row(0).font_style = :bold
      row(0).background_color = 'DDDDDD'
      column(3).align = :right
    end

    if @report_data[:recent_payments][:payments].count > 10
      @pdf.move_down 5
      @pdf.text "※ 上位10件のみ表示（全#{@report_data[:recent_payments][:payments].count}件）", size: 8
    end
  end

  def draw_footer
    @pdf.move_down 30
    @pdf.text "発行日: #{Date.today.strftime('%Y年%m月%d日')}", size: 10, align: :right
    @pdf.text 'みんなの社食', size: 10, align: :right
  end

  def format_currency(amount)
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end

  def calculate_percentage(amount)
    total = @report_data[:summary][:total_amount]
    return 0 if total == 0
    ((amount.to_f / total * 100).round(1))
  end
end
