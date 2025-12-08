require "administrate/field/time"

class TimeWithoutSecondsField < Administrate::Field::Time
  def to_s
    data
  end
end
