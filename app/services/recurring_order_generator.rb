class RecurringOrderGenerator
  attr_reader :start_date, :end_date, :errors

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
    @errors = []
  end

  def self.generate_for_period(start_date, end_date)
    new(start_date, end_date).generate
  end

  def generate
    generated_orders = []

    RecurringOrder.active.current.find_each do |recurring_order|
      begin
        orders = recurring_order.generate_orders_for_range(start_date, end_date)
        generated_orders.concat(orders)
      rescue StandardError => e
        @errors << {
          recurring_order_id: recurring_order.id,
          error: e.message,
          backtrace: e.backtrace.first(5)
        }
      end
    end

    {
      success: @errors.empty?,
      generated_count: generated_orders.size,
      generated_orders: generated_orders,
      errors: @errors
    }
  end

  def generate!
    result = generate
    unless result[:success]
      raise "Order generation failed with #{result[:errors].size} errors"
    end
    result
  end
end
