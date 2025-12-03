namespace :invoices do
  desc '月次請求書を生成 - 使い方: rails invoices:generate_monthly[YEAR,MONTH] または rails invoices:generate_monthly[YEAR,MONTH,COMPANY_ID]'
  task :generate_monthly, [:year, :month, :company_id] => :environment do |_task, args|
    year = args[:year]&.to_i || Date.today.year
    month = args[:month]&.to_i || Date.today.month
    company_id = args[:company_id]&.to_i

    puts "=" * 60
    puts "月次請求書生成タスク"
    puts "対象期間: #{year}年#{month}月"
    puts "=" * 60
    puts ""

    generator = InvoiceGenerator.new

    if company_id.present?
      # 特定企業の請求書を生成
      company = Company.find_by(id: company_id)
      unless company
        puts "❌ エラー: 企業ID #{company_id} が見つかりません"
        exit 1
      end

      puts "対象企業: #{company.name} (ID: #{company.id})"
      puts ""

      invoice = generator.generate_monthly_invoice(company_id, year, month)

      if invoice
        puts "✅ 請求書を生成しました"
        puts "  請求書番号: #{invoice.invoice_number}"
        puts "  企業: #{invoice.company.name}"
        puts "  期間: #{invoice.billing_period_start} 〜 #{invoice.billing_period_end}"
        puts "  明細数: #{invoice.invoice_items.count}件"
        puts "  小計: ¥#{invoice.subtotal.to_s(:delimited)}"
        puts "  消費税: ¥#{invoice.tax_amount.to_s(:delimited)}"
        puts "  合計: ¥#{invoice.total_amount.to_s(:delimited)}"
      else
        puts "❌ 請求書の生成に失敗しました"
        generator.errors.each do |error|
          puts "  - #{error}"
        end
        exit 1
      end
    else
      # 全企業の請求書を一括生成
      puts "対象: 契約中の全企業"
      puts ""

      invoices = generator.generate_all_monthly_invoices(year, month)

      if invoices.any?
        puts "✅ #{invoices.count}件の請求書を生成しました"
        puts ""
        puts "生成された請求書:"
        invoices.each do |invoice|
          puts "  - #{invoice.invoice_number}: #{invoice.company.name} (¥#{invoice.total_amount.to_s(:delimited)})"
        end
      else
        puts "❌ 生成された請求書がありません"
        if generator.errors.any?
          puts ""
          puts "エラー:"
          generator.errors.each do |error|
            puts "  - #{error}"
          end
        end
      end
    end

    puts ""
    puts "=" * 60
    puts "完了"
    puts "=" * 60
  end

  desc '請求書一覧を表示'
  task :list, [:year, :month] => :environment do |_task, args|
    year = args[:year]&.to_i || Date.today.year
    month = args[:month]&.to_i || Date.today.month

    billing_period_start = Date.new(year, month, 1)
    billing_period_end = billing_period_start.end_of_month

    invoices = Invoice.includes(:company)
                      .where(billing_period_start: billing_period_start)
                      .order(:invoice_number)

    puts "=" * 80
    puts "請求書一覧: #{year}年#{month}月"
    puts "=" * 80
    puts ""

    if invoices.any?
      printf("%-20s %-30s %15s %10s %12s\n", "請求書番号", "企業名", "合計金額", "ステータス", "支払状況")
      puts "-" * 80
      invoices.each do |invoice|
        printf("%-20s %-30s %15s %10s %12s\n",
               invoice.invoice_number,
               invoice.company.name.truncate(28),
               "¥#{invoice.total_amount.to_s(:delimited)}",
               invoice.status,
               invoice.payment_status)
      end
      puts ""
      puts "合計: #{invoices.count}件"
      puts "総額: ¥#{invoices.sum(:total_amount).to_s(:delimited)}"
    else
      puts "請求書が見つかりませんでした"
    end

    puts ""
    puts "=" * 80
  end

  desc '未払い請求書を表示'
  task :unpaid => :environment do
    invoices = Invoice.includes(:company)
                      .where.not(payment_status: 'paid')
                      .order(:payment_due_date)

    puts "=" * 80
    puts "未払い請求書一覧"
    puts "=" * 80
    puts ""

    if invoices.any?
      printf("%-20s %-25s %15s %12s %12s\n", "請求書番号", "企業名", "合計金額", "支払期限", "経過日数")
      puts "-" * 80
      invoices.each do |invoice|
        days_info = if invoice.overdue?
                      "#{invoice.days_overdue}日超過"
                    else
                      "残り#{invoice.days_until_due}日"
                    end

        printf("%-20s %-25s %15s %12s %12s\n",
               invoice.invoice_number,
               invoice.company.name.truncate(23),
               "¥#{invoice.total_amount.to_s(:delimited)}",
               invoice.payment_due_date.strftime('%Y/%m/%d'),
               days_info)
      end
      puts ""
      puts "合計: #{invoices.count}件"
      puts "総額: ¥#{invoices.sum(:total_amount).to_s(:delimited)}"
    else
      puts "未払いの請求書はありません"
    end

    puts ""
    puts "=" * 80
  end
end
