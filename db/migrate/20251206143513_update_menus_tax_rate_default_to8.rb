class UpdateMenusTaxRateDefaultTo8 < ActiveRecord::Migration[7.1]
  def up
    # 既存の全メニューを8%に更新
    Menu.update_all(tax_rate: 8)

    # デフォルト値を8%に変更
    change_column_default :menus, :tax_rate, from: 10, to: 8
    change_column_default :order_items, :tax_rate, from: 10, to: 8
  end

  def down
    # ロールバック時は10%に戻す
    change_column_default :menus, :tax_rate, from: 8, to: 10
    change_column_default :order_items, :tax_rate, from: 8, to: 10
  end
end
