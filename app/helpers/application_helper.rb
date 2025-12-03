module ApplicationHelper
  include SimpleCalendar::ViewHelpers

  def nav_link_state(resource_name)
    controller_name = params[:controller]&.split('/')&.last
    resource_name.to_s.pluralize == controller_name ? 'active' : ''
  end
end
