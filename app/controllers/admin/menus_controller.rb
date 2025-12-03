module Admin
  class MenusController < Admin::ApplicationController
    # フィルター・検索機能を追加
    def scoped_resource
      resources = super

      # メニュー名検索
      if params[:search].present?
        resources = resources.where("name LIKE ?", "%#{params[:search]}%")
      end

      # 飲食店フィルター
      if params[:restaurant_id].present?
        resources = resources.where(restaurant_id: params[:restaurant_id])
      end

      # ステータスフィルター
      if params[:is_active].present?
        resources = resources.where(is_active: params[:is_active] == "true")
      end

      resources
    end
  end
end
