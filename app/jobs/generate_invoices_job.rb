class GenerateInvoicesJob < ApplicationJob
  queue_as :invoices

  # 月次請求書を一括生成
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @param company_ids [Array<Integer>, nil] 対象企業ID配列（nilの場合は全企業）
  def perform(year, month, company_ids: nil)
    Rails.logger.info "Starting invoice generation for #{year}/#{month}"
    Rails.logger.info "Target companies: #{company_ids || 'all active companies'}"

    generator = InvoiceGenerator.new
    invoices = generator.generate_all_monthly_invoices(year, month, company_ids: company_ids)

    if invoices.any?
      Rails.logger.info "Successfully generated #{invoices.count} invoices"
      invoices.each do |invoice|
        Rails.logger.info "  - #{invoice.invoice_number}: #{invoice.company.name} (¥#{invoice.total_amount})"
      end
    else
      Rails.logger.warn "No invoices were generated"
      generator.errors.each do |error|
        Rails.logger.warn "  - #{error}"
      end
    end

    # 生成結果を返す
    {
      success: invoices.any?,
      count: invoices.count,
      invoice_ids: invoices.map(&:id),
      errors: generator.errors
    }
  rescue StandardError => e
    Rails.logger.error "Failed to generate invoices: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
