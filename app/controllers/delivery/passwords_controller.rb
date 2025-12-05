class Delivery::PasswordsController < Devise::PasswordsController
  layout 'delivery_application'

  # GET /delivery/password/new
  def new
    super
  end

  # POST /delivery/password
  def create
    super
  end

  # GET /delivery/password/edit?reset_password_token=abcdef
  def edit
    super
  end

  # PUT /delivery/password
  def update
    super
  end

  protected

  def after_resetting_password_path_for(resource)
    delivery_root_path
  end

  def after_sending_reset_password_instructions_path_for(resource_name)
    new_delivery_user_session_path
  end
end
