# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_admin
    helper SimpleCalendar::CalendarHelper

    def authenticate_admin
      authenticate_admin_user!
    end

    # Administrateの認可をオーバーライド
    # 認証されたadmin_userは全てのリソースにアクセス可能
    def authorize_resource(resource)
      # 何もしない = 全て許可
    end

    def valid_action?(name, resource = resource_class)
      # 全てのアクションを許可
      true
    end

    def show_action?(action, resource)
      # 全てのアクションを表示
      true
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
