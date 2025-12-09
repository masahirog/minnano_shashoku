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
      csv_data = @report_generator.generate_csv

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
  end
end
