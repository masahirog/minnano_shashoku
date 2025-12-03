module Admin
  class OrdersController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # カレンダー表示アクション
    def calendar
      start_date = params.fetch(:start_date, Date.today).to_date
      @orders = Order.includes(:company, :restaurant, :menu)
                     .where(scheduled_date: start_date.beginning_of_month..start_date.end_of_month)

      # フィルター適用
      @orders = @orders.where(company_id: params[:company_id]) if params[:company_id].present?
      @orders = @orders.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
      @orders = @orders.where(status: params[:status]) if params[:status].present?

      @orders = @orders.order(:scheduled_date, :collection_time)
    end

    # スケジュール調整画面
    def schedule
      @start_date = params.fetch(:start_date, Date.today).to_date
      @end_date = params.fetch(:end_date, @start_date + 1.month).to_date

      @orders = Order.includes(:company, :restaurant, :menu, :delivery_company)
                     .where(scheduled_date: @start_date..@end_date)

      # フィルター適用
      @orders = @orders.where(company_id: params[:company_id]) if params[:company_id].present?
      @orders = @orders.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
      @orders = @orders.where(status: params[:status]) if params[:status].present?

      @orders = @orders.order(:scheduled_date, :collection_time)
    end

    # スケジュール一括更新
    def update_schedule
      order_updates = params[:orders] || {}
      errors = []
      success_count = 0

      order_updates.each do |order_id, attributes|
        order = Order.find_by(id: order_id)
        next unless order

        if order.update(attributes.permit(:scheduled_date, :collection_time))
          success_count += 1
        else
          errors << "Order ##{order_id}: #{order.errors.full_messages.join(', ')}"
        end
      end

      if errors.empty?
        redirect_to schedule_admin_orders_path, notice: "#{success_count}件の案件を更新しました。"
      else
        redirect_to schedule_admin_orders_path, alert: "エラー: #{errors.join('; ')}"
      end
    end

    # 配送シート画面
    def delivery_sheets
      @start_date = params.fetch(:start_date, Date.today).to_date
      @end_date = params.fetch(:end_date, @start_date + 7.days).to_date

      @orders = Order.includes(:company, :restaurant, :menu, :delivery_company)
                     .where(scheduled_date: @start_date..@end_date)
                     .where.not(status: 'cancelled')

      # フィルター適用
      @orders = @orders.where(company_id: params[:company_id]) if params[:company_id].present?
      @orders = @orders.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
      @orders = @orders.where(delivery_company_id: params[:delivery_company_id]) if params[:delivery_company_id].present?

      @orders = @orders.order(:scheduled_date, :collection_time)
    end

    # 配送シートPDF出力
    def delivery_sheet_pdf
      start_date = params.fetch(:start_date, Date.today).to_date
      end_date = params.fetch(:end_date, start_date + 7.days).to_date

      @orders = Order.includes(:company, :restaurant, :menu, :delivery_company)
                     .where(scheduled_date: start_date..end_date)
                     .where.not(status: 'cancelled')

      # フィルター適用
      @orders = @orders.where(company_id: params[:company_id]) if params[:company_id].present?
      @orders = @orders.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
      @orders = @orders.where(delivery_company_id: params[:delivery_company_id]) if params[:delivery_company_id].present?

      @orders = @orders.order(:scheduled_date, :collection_time)

      # PDF生成
      pdf = DeliverySheetPdfGenerator.new(@orders, start_date: start_date, end_date: end_date).generate

      # PDFをダウンロード
      send_data pdf,
                filename: "delivery_sheet_#{start_date.strftime('%Y%m%d')}-#{end_date.strftime('%Y%m%d')}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes(action_name)).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
