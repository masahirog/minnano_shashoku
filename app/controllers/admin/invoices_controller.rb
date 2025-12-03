module Admin
  class InvoicesController < Admin::ApplicationController
    def show_pdf
      invoice = Invoice.includes(:company, invoice_items: :order).find(params[:id])

      pdf = InvoicePdfGenerator.new(invoice).generate

      send_data pdf,
                filename: "invoice_#{invoice.invoice_number}_#{Date.today.strftime('%Y%m%d')}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
    end
  end
end
