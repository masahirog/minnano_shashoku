module Admin
  class RestaurantsController < Admin::ApplicationController
    # Override update to handle photo deletion
    def update
      # 削除対象の写真を処理
      if params[:restaurant][:remove_pickup_photos].present?
        params[:restaurant][:remove_pickup_photos].each do |attachment_id|
          attachment = ActiveStorage::Attachment.find_by(id: attachment_id)
          attachment&.purge
        end
      end

      # 空のpickup_photosパラメータを削除（新しいファイルが選択されていない場合）
      if params[:restaurant][:pickup_photos].present?
        # 空文字列のみの配列の場合はパラメータを削除
        params[:restaurant].delete(:pickup_photos) if params[:restaurant][:pickup_photos].all?(&:blank?)
      end

      super
    end

    # Override `resource_params` to handle array parameters (closed_days, pickup_photos)
    def resource_params
      permitted_params = dashboard.permitted_attributes(action_name)

      # closed_daysとpickup_photosを配列として許可
      params.require(resource_class.model_name.param_key).permit(
        *permitted_params,
        closed_days: [],
        pickup_photos: [],
        remove_pickup_photos: []
      )
    end
  end
end
