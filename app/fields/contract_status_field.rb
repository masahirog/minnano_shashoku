require "administrate/field/string"

class ContractStatusField < Administrate::Field::String
  def to_s
    data
  end
end
