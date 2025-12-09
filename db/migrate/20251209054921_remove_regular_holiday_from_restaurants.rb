class RemoveRegularHolidayFromRestaurants < ActiveRecord::Migration[7.1]
  def change
    remove_column :restaurants, :regular_holiday, :string
  end
end
