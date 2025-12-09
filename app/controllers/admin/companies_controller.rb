module Admin
  class CompaniesController < Admin::ApplicationController
    def resource_params
      params.require(resource_class.model_name.param_key).
        permit(dashboard.permitted_attributes(action_name),
               recurring_orders_attributes: [:id, :day_of_week, :meal_count, :delivery_time, :pickup_time, :status, :is_active, :notes, :_destroy])
    end
  end
end
