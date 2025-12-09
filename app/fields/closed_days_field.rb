require "administrate/field/string"

class ClosedDaysField < Administrate::Field::String
  def to_s
    data
  end
end
