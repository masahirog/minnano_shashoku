class AdminUsers::RegistrationsController < Devise::RegistrationsController
  layout 'administrate/application'

  # 新規登録を無効化
  def new
    redirect_to admin_root_path
  end

  def create
    redirect_to admin_root_path
  end
end
