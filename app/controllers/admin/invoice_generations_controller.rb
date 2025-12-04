module Admin
  class InvoiceGenerationsController < Admin::ApplicationController
    skip_before_action :authorize_resource, raise: false

    def create
      year = params[:year].to_i
      month = params[:month].to_i
      company_ids = params[:company_ids].presence

      # バリデーション
      if year < 2000 || year > 2100
        redirect_to admin_invoices_path, alert: '有効な年を指定してください。' and return
      end

      if month < 1 || month > 12
        redirect_to admin_invoices_path, alert: '有効な月を指定してください。' and return
      end

      generator = InvoiceGenerator.new
      invoices = generator.generate_all_monthly_invoices(year, month, company_ids: company_ids)

      if invoices.any?
        flash[:notice] = "#{year}年#{month}月の請求書を#{invoices.count}件生成しました。"

        # エラーがある場合は警告も表示
        if generator.errors.any?
          flash[:alert] = "一部の企業で請求書を生成できませんでした: #{generator.errors.join(', ')}"
        end
      else
        if generator.errors.any?
          flash[:alert] = "請求書を生成できませんでした: #{generator.errors.join(', ')}"
        else
          flash[:alert] = "#{year}年#{month}月の対象となる案件が見つかりませんでした。"
        end
      end

      redirect_to admin_invoices_path
    rescue StandardError => e
      Rails.logger.error "請求書一括生成エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to admin_invoices_path, alert: '請求書生成中にエラーが発生しました。'
    end
  end
end
