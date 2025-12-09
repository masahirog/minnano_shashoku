require "administrate/field/string"

class GenreField < Administrate::Field::String
  def to_s
    data
  end
end
