namespace :orders do
  desc "Generate orders from recurring schedules for next N weeks (default: 4)"
  task :generate, [:weeks] => :environment do |_t, args|
    weeks = args[:weeks]&.to_i || 4
    start_date = Date.today
    end_date = start_date + weeks.weeks

    puts "=" * 80
    puts "Generating orders from recurring schedules"
    puts "Period: #{start_date} to #{end_date} (#{weeks} weeks)"
    puts "=" * 80
    puts ""

    result = RecurringOrderGenerator.generate_for_period(start_date, end_date)

    if result[:success]
      puts "✓ Successfully generated #{result[:generated_count]} orders"

      if result[:generated_orders].any?
        puts ""
        puts "Generated orders by company:"
        result[:generated_orders].group_by(&:company).each do |company, orders|
          puts "  - #{company.name}: #{orders.size} orders"
        end
      end
    else
      puts "✗ Generation completed with #{result[:errors].size} errors"
      puts ""
      puts "Errors:"
      result[:errors].each do |error|
        puts "  - RecurringOrder ##{error[:recurring_order_id]}: #{error[:error]}"
      end
      puts ""
      puts "Successfully generated: #{result[:generated_count]} orders"
    end

    puts ""
    puts "=" * 80
    puts "Done!"
    puts "=" * 80
  end

  desc "Clear all future orders generated from recurring schedules"
  task :clear_future_recurring => :environment do
    future_orders = Order.where('scheduled_date > ?', Date.today)
                         .where.not(recurring_order_id: nil)

    count = future_orders.count

    print "Are you sure you want to delete #{count} future recurring orders? (y/n): "
    input = STDIN.gets.chomp

    if input.downcase == 'y'
      future_orders.destroy_all
      puts "✓ Deleted #{count} orders"
    else
      puts "Cancelled"
    end
  end
end
