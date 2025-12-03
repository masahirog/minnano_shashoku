class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.references :company, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.date :issue_date, null: false
      t.date :payment_due_date, null: false
      t.date :billing_period_start, null: false
      t.date :billing_period_end, null: false
      t.integer :subtotal, default: 0
      t.integer :tax_amount, default: 0
      t.integer :total_amount, null: false
      t.string :status, null: false, default: 'draft'
      t.string :payment_status, default: 'unpaid'
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :issue_date
    add_index :invoices, :status
    add_index :invoices, :payment_status
  end
end
