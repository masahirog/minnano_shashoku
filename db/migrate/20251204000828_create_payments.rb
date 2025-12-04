class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.date :payment_date, null: false
      t.integer :amount, null: false
      t.string :payment_method
      t.string :reference_number
      t.text :notes

      t.timestamps
    end

    add_index :payments, :payment_date
    add_index :payments, :payment_method
  end
end
