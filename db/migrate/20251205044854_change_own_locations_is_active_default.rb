class ChangeOwnLocationsIsActiveDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default :own_locations, :is_active, from: nil, to: true
  end
end
