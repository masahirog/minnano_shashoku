class GenerateOrdersJob < ApplicationJob
  queue_as :default

  # 定期的にOrderを生成するジョブ
  # 引数: weeks - 何週間先まで生成するか（デフォルト: 4週間）
  def perform(weeks = 4)
    start_date = Date.today
    end_date = start_date + weeks.weeks

    Rails.logger.info "Starting order generation for #{weeks} weeks (#{start_date} to #{end_date})"

    result = RecurringOrderGenerator.generate_for_period(start_date, end_date)

    if result[:success]
      Rails.logger.info "Successfully generated #{result[:generated_count]} orders"
    else
      Rails.logger.error "Order generation completed with #{result[:errors].size} errors"
      result[:errors].each do |error|
        Rails.logger.error "  RecurringOrder ##{error[:recurring_order_id]}: #{error[:error]}"
      end
    end

    result
  end
end
