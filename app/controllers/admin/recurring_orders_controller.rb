module Admin
  class RecurringOrdersController < Admin::ApplicationController
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

    # 一括注文生成アクション
    def bulk_generate
      weeks = params[:weeks]&.to_i || 4
      start_date = Date.today
      end_date = start_date + weeks.weeks

      result = RecurringOrderGenerator.generate_for_period(start_date, end_date)

      if result[:success]
        flash[:notice] = "#{result[:generated_count]}件の注文を生成しました"
      else
        flash[:error] = "#{result[:errors].size}件のエラーが発生しました。生成: #{result[:generated_count]}件"
      end

      redirect_to admin_recurring_orders_path
    end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
