class Delivery::BaseController < ApplicationController
  layout 'delivery_application'
  before_action :authenticate_delivery_user!
  before_action :check_active_status

  private

  def check_active_status
    unless current_delivery_user&.is_active?
      sign_out current_delivery_user
      redirect_to new_delivery_user_session_path, alert: 'アカウントが無効化されています。管理者に連絡してください。'
    end
  end
end
