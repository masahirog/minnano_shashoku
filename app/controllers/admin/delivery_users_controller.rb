module Admin
  class DeliveryUsersController < Admin::ApplicationController
    # Override resource_params to handle Devise password fields
    def resource_params
      permitted_params = dashboard.permitted_attributes(action_name)
      params_hash = params.require(resource_class.model_name.param_key).permit(*permitted_params)

      # パスワードが空の場合は削除（編集時にパスワード変更しない場合）
      if params_hash[:password].blank? && params_hash[:password_confirmation].blank?
        params_hash.delete(:password)
        params_hash.delete(:password_confirmation)
      end

      params_hash
    end

    # 検索機能のカスタマイズ
    def scoped_resource
      resource_class.includes(:delivery_company)
    end

    # 削除前の確認メッセージをカスタマイズ
    def destroy
      if requested_resource.delivery_assignments.exists?
        flash[:alert] = "配送割当が存在するため、削除できません。先に配送割当を削除してください。"
        redirect_to admin_delivery_user_path(requested_resource)
      else
        super
      end
    end
  end
end
