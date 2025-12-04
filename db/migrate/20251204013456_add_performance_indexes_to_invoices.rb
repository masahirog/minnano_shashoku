class AddPerformanceIndexesToInvoices < ActiveRecord::Migration[7.1]
  def change
    # レポート生成で頻繁に使用される billing_period_start にインデックスを追加
    add_index :invoices, :billing_period_start, if_not_exists: true

    # 期限超過チェックで頻繁に使用される payment_due_date にインデックスを追加
    add_index :invoices, :payment_due_date, if_not_exists: true

    # レポート生成でbilling_period_startとpayment_statusの組み合わせで検索することが多いため
    # 複合インデックスを追加（オプショナル：さらなる高速化）
    add_index :invoices, [:billing_period_start, :payment_status], if_not_exists: true, name: 'index_invoices_on_billing_period_and_status'
  end
end
