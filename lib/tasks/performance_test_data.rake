namespace :performance do
  desc "大量データを生成してパフォーマンステストを実施"
  task generate_test_data: :environment do
    puts "パフォーマンステスト用データの生成を開始します..."

    # トランザクション内で実行
    ActiveRecord::Base.transaction do
      # 既存のCompanyを取得または作成
      companies = []
      10.times do |i|
        companies << Company.find_or_create_by!(
          name: "テスト企業#{i + 1}",
          formal_name: "株式会社テスト企業#{i + 1}",
          contract_status: 'active',
          billing_email: "test#{i + 1}@example.com"
        )
      end
      puts "✓ 10社の企業データを作成しました"

      # 100件以上の請求書を生成
      invoices_count = 0
      invoice_items_count = 0
      payments_count = 0

      companies.each do |company|
        # 各企業に10-15件の請求書を作成
        invoice_count_per_company = rand(10..15)

        invoice_count_per_company.times do |i|
          # 過去6ヶ月分の請求書を作成
          billing_month = Date.today - (invoice_count_per_company - i).months
          billing_period_start = billing_month.beginning_of_month
          billing_period_end = billing_month.end_of_month
          issue_date = billing_period_end + 1.day
          payment_due_date = issue_date + 30.days

          # payment_statusをランダムに設定
          payment_status = ['unpaid', 'partial', 'paid', 'overdue'].sample
          status = payment_status == 'paid' ? 'paid' : 'sent'

          invoice = Invoice.create!(
            company: company,
            issue_date: issue_date,
            payment_due_date: payment_due_date,
            billing_period_start: billing_period_start,
            billing_period_end: billing_period_end,
            subtotal: 0,
            tax_amount: 0,
            total_amount: 0,
            status: status,
            payment_status: payment_status
          )
          invoices_count += 1

          # 各請求書に3-8件の明細を追加
          items_count = rand(3..8)
          subtotal = 0

          items_count.times do
            quantity = rand(10..100)
            unit_price = [500, 600, 649, 700, 800].sample
            amount = quantity * unit_price
            subtotal += amount

            invoice.invoice_items.create!(
              description: "試食会サービス #{['A', 'B', 'C', 'D'].sample}プラン",
              quantity: quantity,
              unit_price: unit_price,
              amount: amount
            )
            invoice_items_count += 1
          end

          # 請求書の金額を更新
          tax_amount = (subtotal * 0.1).round
          total_amount = subtotal + tax_amount
          invoice.update_columns(
            subtotal: subtotal,
            tax_amount: tax_amount,
            total_amount: total_amount
          )

          # 支払済みまたは一部支払の場合、入金レコードを作成
          if ['paid', 'partial'].include?(payment_status)
            if payment_status == 'paid'
              # 全額支払
              invoice.payments.create!(
                payment_date: payment_due_date - rand(0..15).days,
                amount: total_amount,
                payment_method: ['銀行振込', 'クレジットカード', '現金'].sample
              )
              payments_count += 1
            else
              # 一部支払（50-80%）
              payment_ratio = rand(50..80) / 100.0
              invoice.payments.create!(
                payment_date: payment_due_date - rand(0..10).days,
                amount: (total_amount * payment_ratio).round,
                payment_method: ['銀行振込', 'クレジットカード'].sample
              )
              payments_count += 1
            end
          end
        end
      end

      puts "✓ #{invoices_count}件の請求書を作成しました"
      puts "✓ #{invoice_items_count}件の請求書明細を作成しました"
      puts "✓ #{payments_count}件の入金レコードを作成しました"

      # 在庫データも生成
      supplies_count = 0
      supply_stocks_count = 0

      50.times do |i|
        supply = Supply.find_or_create_by!(
          sku: "PERF-TEST-#{i.to_s.rjust(4, '0')}"
        ) do |s|
          s.name = "テスト備品#{i + 1}"
          s.category = ['使い捨て備品', '企業貸与備品', '飲食店貸与備品'].sample
          s.unit = ['個', 'セット', 'パック'].sample
          s.reorder_point = rand(10..50)
          s.is_active = true
        end
        supplies_count += 1

        # 各備品に2-4個の在庫ロケーションを作成
        locations_count = rand(2..4)
        locations_count.times do
          supply.supply_stocks.find_or_create_by!(
            location_name: ['本社', '倉庫A', '倉庫B', '試食会会場'].sample
          ) do |stock|
            stock.quantity = rand(0..100)
          end
          supply_stocks_count += 1
        end
      end

      puts "✓ #{supplies_count}件の備品データを作成しました"
      puts "✓ #{supply_stocks_count}件の在庫データを作成しました"

      puts "\nパフォーマンステスト用データの生成が完了しました！"
      puts "=" * 60
      puts "データ統計:"
      puts "  企業: #{Company.count}社"
      puts "  請求書: #{Invoice.count}件"
      puts "  請求書明細: #{InvoiceItem.count}件"
      puts "  入金: #{Payment.count}件"
      puts "  備品: #{Supply.count}件"
      puts "  在庫: #{SupplyStock.count}ロケーション"
      puts "=" * 60
    end
  end

  desc "パフォーマンステスト用データを削除"
  task clean_test_data: :environment do
    puts "パフォーマンステスト用データの削除を開始します..."

    # テストデータのみを削除
    ActiveRecord::Base.transaction do
      # テスト企業の請求書とそれに関連するデータを削除
      test_companies = Company.where("name LIKE ?", "テスト企業%")
      test_companies.each do |company|
        company.invoices.destroy_all
      end

      # テスト企業を削除
      deleted_companies = test_companies.destroy_all.size

      # テスト備品を削除
      test_supplies = Supply.where("sku LIKE ?", "PERF-TEST-%")
      deleted_supplies = test_supplies.destroy_all.size

      puts "✓ #{deleted_companies}社のテスト企業と関連データを削除しました"
      puts "✓ #{deleted_supplies}件のテスト備品と関連データを削除しました"
      puts "パフォーマンステスト用データの削除が完了しました"
    end
  end

  desc "パフォーマンスベンチマークを実行"
  task benchmark: :environment do
    require 'benchmark'

    puts "パフォーマンスベンチマークを実行します..."
    puts "=" * 60

    # 1. レポート生成のベンチマーク
    puts "\n【レポート生成のベンチマーク】"
    result = Benchmark.measure do
      generator = ReportGeneratorService.new(year: Date.today.year, month: Date.today.month)
      @report_data = generator.generate_monthly_payment_report
    end
    puts "実行時間: #{result.real.round(3)}秒"
    puts result.real < 1.0 ? "✓ 目標達成（1秒以内）" : "✗ 目標未達成（1秒以上かかりました）"

    # 2. 請求書一覧取得のベンチマーク
    puts "\n【請求書一覧取得（100件）のベンチマーク】"
    result = Benchmark.measure do
      @invoices = Invoice.includes(:company, :invoice_items, :payments).limit(100).to_a
    end
    puts "実行時間: #{result.real.round(3)}秒"
    puts result.real < 0.5 ? "✓ 目標達成（0.5秒以内）" : "✗ 目標未達成"

    # 3. 期限超過チェックのベンチマーク
    puts "\n【期限超過チェックのベンチマーク】"
    result = Benchmark.measure do
      checker = UnpaidInvoiceChecker.new
      @overdue = checker.check_overdue
    end
    puts "実行時間: #{result.real.round(3)}秒"
    puts "検出件数: #{@overdue.count}件"
    puts result.real < 0.5 ? "✓ 目標達成（0.5秒以内）" : "✗ 目標未達成"

    # 4. 在庫不足チェックのベンチマーク
    puts "\n【在庫不足チェックのベンチマーク】"
    result = Benchmark.measure do
      checker = LowStockChecker.new
      @low_stock_result = checker.check_all
    end
    puts "実行時間: #{result.real.round(3)}秒"
    puts "在庫不足: #{@low_stock_result[:low_stock_count]}件"
    puts "在庫切れ: #{@low_stock_result[:out_of_stock_count]}件"
    puts result.real < 0.5 ? "✓ 目標達成（0.5秒以内）" : "✗ 目標未達成"

    puts "\n" + "=" * 60
    puts "ベンチマーク完了"
  end
end
