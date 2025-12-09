require "administrate/field/number"

class CurrencyField < Administrate::Field::Number
  def to_s
    # カンマ区切りで表示
    number_with_delimiter(data)
  end

  private

  def number_with_delimiter(number)
    return "" if number.nil?
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
