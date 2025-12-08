require "administrate/field/base"

class NestedHasManyField < Administrate::Field::HasMany
  def to_s
    data
  end

  def associated_resource_options
    candidate_resources.map do |resource|
      [display_candidate_resource(resource), resource.send(associated_primary_key)]
    end
  end

  def candidate_resources
    associated_class.all
  end

  def display_candidate_resource(resource)
    associated_dashboard.display_resource(resource)
  end

  def associated_primary_key
    options.fetch(:primary_key, :id)
  end

  def associated_dashboard
    "#{associated_class_name}Dashboard".constantize.new
  end

  def associated_class_name
    options.fetch(:class_name, attribute.to_s.singularize.camelcase)
  end

  def associated_class
    associated_class_name.constantize
  end

  def nested_form
    true
  end

  def to_partial_path
    if attribute == :recurring_orders
      "/fields/nested_has_many_field/recurring_orders"
    else
      "/fields/nested_has_many_field/form"
    end
  end
end
