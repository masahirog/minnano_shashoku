class CreateInvoiceItems < ActiveRecord::Migration[7.1]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :order, foreign_key: true
      t.string :description, null: false
      t.integer :quantity, default: 1
      t.integer :unit_price, null: false
      t.integer :amount, null: false

      t.timestamps
    end
  end
end
