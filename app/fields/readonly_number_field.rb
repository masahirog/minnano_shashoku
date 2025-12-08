require "administrate/field/number"

class ReadonlyNumberField < Administrate::Field::Number
  def to_s
    data
  end
end
