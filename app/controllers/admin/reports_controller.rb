module Admin
  class ReportsController < Admin::ApplicationController
    def index
      @year = params[:year]&.to_i || Date.today.year
      @month = params[:month]&.to_i || Date.today.month

      @report_generator = ReportGeneratorService.new(year: @year, month: @month)
      @report_data = @report_generator.generate_monthly_payment_report

      respond_to do |format|
        format.html
        format.json { render json: @report_data }
      end
    end

    def export_pdf
      @year = params[:year]&.to_i || Date.today.year
      @month = params[:month]&.to_i || Date.today.month

      @report_generator = ReportGeneratorService.new(year: @year, month: @month)
      @report_data = @report_generator.generate_monthly_payment_report

      pdf = ReportPdfGenerator.new(@report_data).generate

      send_data pdf.render,
                filename: "payment_report_#{@year}_#{@month}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    end

    def export_csv
      @year = params[:year]&.to_i || Date.today.year
      @month = params[:month]&.to_i || Date.today.month

      @report_generator = ReportGeneratorService.new(year: @year, month: @month)
      @report_data = @report_generator.generate_monthly_payment_report

      csv_data = generate_csv(@report_data)

      send_data csv_data,
                filename: "payment_report_#{@year}_#{@month}.csv",
                type: 'text/csv',
                disposition: 'attachment'
    end

    def chart_data
      @year = params[:year]&.to_i || Date.today.year
      @month = params[:month]&.to_i || Date.today.month

      @report_generator = ReportGeneratorService.new(year: @year, month: @month)

      data = {
        by_status: @report_generator.chart_data_by_status,
        by_company: @report_generator.chart_data_by_company
      }

      render json: data
    end

    private

    def generate_csv(report_data)
      require 'csv'

      CSV.generate(headers: true) do |csv|
        # サマリー情報
        csv << ['月次支払レポート']
        csv << ['対象期間', "#{report_data[:period][:year]}年#{report_data[:period][:month]}月"]
        csv << []

        csv << ['サマリー']
        csv << ['項目', '値']
        csv << ['総請求書数', report_data[:summary][:total_invoices]]
        csv << ['総請求額', report_data[:summary][:total_amount]]
        csv << ['支払済み額', report_data[:summary][:paid_amount]]
        csv << ['未払い額', report_data[:summary][:unpaid_amount]]
        csv << ['支払率(%)', report_data[:summary][:payment_rate]]
        csv << []

        # 支払ステータス別
        csv << ['支払ステータス別集計']
        csv << ['ステータス', '件数', '金額']
        csv << ['支払済み', report_data[:by_status][:paid][:count], report_data[:by_status][:paid][:amount]]
        csv << ['一部支払', report_data[:by_status][:partial][:count], report_data[:by_status][:partial][:amount]]
        csv << ['未払い', report_data[:by_status][:unpaid][:count], report_data[:by_status][:unpaid][:amount]]
        csv << ['期限超過', report_data[:by_status][:overdue][:count], report_data[:by_status][:overdue][:amount]]
        csv << []

        # 企業別
        csv << ['企業別支払状況']
        csv << ['企業名', '請求書数', '総請求額', '支払済み額', '未払い額']
        report_data[:by_company].each do |company|
          csv << [
            company[:company_name],
            company[:invoice_count],
            company[:total_amount],
            company[:paid_amount],
            company[:unpaid_amount]
          ]
        end
        csv << []

        # 期限超過
        if report_data[:overdue][:count] > 0
          csv << ['期限超過請求書']
          csv << ['請求書番号', '企業名', '支払期限', '請求額', '支払済み額', '残高', '超過日数']
          report_data[:overdue][:invoices].each do |invoice|
            csv << [
              invoice[:invoice_number],
              invoice[:company_name],
              invoice[:payment_due_date],
              invoice[:total_amount],
              invoice[:paid_amount],
              invoice[:remaining_balance],
              invoice[:days_overdue]
            ]
          end
        end
      end
    end
  end
end
