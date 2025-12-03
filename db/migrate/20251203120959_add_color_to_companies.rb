class AddColorToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :color, :string, default: '#2196f3'

    # 既存の企業データに色を設定
    reversible do |dir|
      dir.up do
        colors = ['#2196f3', '#4caf50', '#ff9800', '#9c27b0', '#f44336', '#00bcd4', '#ffeb3b', '#e91e63']
        Company.reset_column_information
        Company.find_each.with_index do |company, index|
          company.update_column(:color, colors[index % colors.size])
        end
      end
    end
  end
end
