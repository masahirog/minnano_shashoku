namespace :supplies do
  desc '在庫状況をチェックしてアラートメールを送信'
  task :check_stock => :environment do
    puts "=" * 60
    puts "在庫チェックタスク"
    puts "=" * 60
    puts ""

    checker = LowStockChecker.new
    result = checker.check_all

    puts "在庫チェック結果:"
    puts "  在庫不足: #{result[:low_stock_count]}件"
    puts "  在庫切れ: #{result[:out_of_stock_count]}件"
    puts "  合計アラート: #{result[:total_alerts]}件"
    puts ""

    if result[:low_stock_count] > 0
      puts "在庫不足の備品:"
      result[:low_stock_supplies].each do |supply|
        puts "  - #{supply.name} (SKU: #{supply.sku}): #{supply.total_stock} #{supply.unit} (発注点: #{supply.reorder_point})"
      end
      puts ""
    end

    if result[:out_of_stock_count] > 0
      puts "在庫切れの備品:"
      result[:out_of_stock_supplies].each do |supply|
        puts "  - #{supply.name} (SKU: #{supply.sku}): 0 #{supply.unit}"
      end
      puts ""
    end

    # メール送信
    if result[:total_alerts] > 0
      puts "アラートメールを送信中..."
      mail_result = checker.send_all_alerts

      puts "✅ アラートメール送信完了"
      puts "  在庫不足アラート: #{mail_result[:low_stock_sent]}件"
      puts "  在庫切れアラート: #{mail_result[:out_of_stock_sent]}件"
      puts "  合計送信: #{mail_result[:total_sent]}件"
      puts ""
    else
      puts "✅ 在庫アラートはありません"
      puts ""
    end

    puts "=" * 60
    puts "完了"
    puts "=" * 60
  end

  desc '在庫状況一覧を表示'
  task :list => :environment do
    puts "=" * 80
    puts "在庫状況一覧"
    puts "=" * 80
    puts ""

    supplies = Supply.where(is_active: true).order(:category, :name)

    if supplies.any?
      printf("%-15s %-30s %-20s %10s %10s %8s\n", "SKU", "備品名", "カテゴリ", "現在庫", "発注点", "ステータス")
      puts "-" * 80

      supplies.each do |supply|
        total_stock = supply.total_stock
        status = if total_stock == 0
                  "在庫切れ"
                elsif supply.needs_reorder?
                  "要発注"
                else
                  "正常"
                end

        printf("%-15s %-30s %-20s %10s %10s %8s\n",
               supply.sku.to_s.truncate(15),
               supply.name.to_s.truncate(28),
               supply.category.to_s.truncate(18),
               "#{total_stock} #{supply.unit}",
               supply.reorder_point ? "#{supply.reorder_point} #{supply.unit}" : "-",
               status)
      end
      puts ""
      puts "合計: #{supplies.count}件"
    else
      puts "備品が登録されていません"
    end

    puts ""
    puts "=" * 80
  end

  desc '低在庫備品のみを表示'
  task :low_stock => :environment do
    checker = LowStockChecker.new
    checker.check_all

    puts "=" * 80
    puts "在庫不足・在庫切れ一覧"
    puts "=" * 80
    puts ""

    low_stock = checker.low_stock_supplies
    out_of_stock = checker.out_of_stock_supplies

    if out_of_stock.any?
      puts "【在庫切れ】"
      out_of_stock.each do |supply|
        puts "  ❌ #{supply.name} (SKU: #{supply.sku}): 0 #{supply.unit}"
      end
      puts ""
    end

    if low_stock.any?
      puts "【在庫不足】"
      low_stock.each do |supply|
        puts "  ⚠️  #{supply.name} (SKU: #{supply.sku}): #{supply.total_stock} #{supply.unit} (発注点: #{supply.reorder_point})"
      end
      puts ""
    end

    if low_stock.empty? && out_of_stock.empty?
      puts "✅ 在庫アラートはありません"
      puts ""
    end

    puts "=" * 80
  end
end
