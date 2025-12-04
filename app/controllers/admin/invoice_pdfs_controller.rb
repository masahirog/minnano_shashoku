module Admin
  class InvoicePdfsController < Admin::ApplicationController
    skip_before_action :authorize_resource, raise: false

    def show
      invoice = Invoice.includes(:company, invoice_items: :order).find(params[:id])

      pdf = InvoicePdfGenerator.new(invoice).generate

      send_data pdf,
                filename: "invoice_#{invoice.invoice_number}_#{Date.today.strftime('%Y%m%d')}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_invoices_path, alert: '請求書が見つかりませんでした。'
    rescue StandardError => e
      Rails.logger.error "PDF生成エラー: #{e.message}"
      redirect_to admin_invoices_path, alert: 'PDF生成中にエラーが発生しました。'
    end
  end
end
