class Delivery::SessionsController < Devise::SessionsController
  layout 'delivery_application'

  # GET /delivery/login
  def new
    super
  end

  # POST /delivery/login
  def create
    super
  end

  # DELETE /delivery/logout
  def destroy
    super
  end

  protected

  def after_sign_in_path_for(resource)
    delivery_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_delivery_user_session_path
  end
end
