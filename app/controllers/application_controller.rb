class ApplicationController < ActionController::Base
  layout :layout_by_resource
  helper SimpleCalendar::CalendarHelper

  private

  def layout_by_resource
    if devise_controller?
      # registrations#edit uses administrate layout
      if params[:controller] == "devise/registrations" && params[:action] == "edit"
        "administrate/application"
      else
        "devise"
      end
    else
      "application"
    end
  end
end
