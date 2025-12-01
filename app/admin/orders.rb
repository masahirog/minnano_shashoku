ActiveAdmin.register Order do
  permit_params :company_id, :restaurant_id, :menu_id, :second_menu_id, :delivery_company_id,
                :order_type, :scheduled_date, :delivery_group, :delivery_priority,
                :default_meal_count, :confirmed_meal_count,
                :status, :restaurant_status, :delivery_company_status,
                options: {}

  index do
    selectable_column
    id_column
    column :scheduled_date
    column :company
    column :restaurant
    column :menu
    column :order_type
    column :default_meal_count
    column :confirmed_meal_count
    column :status
    column :delivery_company
    actions
  end

  filter :scheduled_date
  filter :company
  filter :restaurant
  filter :menu
  filter :order_type
  filter :status
  filter :delivery_company
  filter :created_at

  form do |f|
    f.inputs '基本情報' do
      f.input :scheduled_date, label: '実施予定日'
      f.input :company, label: '導入企業'
      f.input :restaurant, label: '飲食店'
      f.input :menu, label: 'メニュー'
      f.input :second_menu, label: '2つ目のメニュー（任意）'
      f.input :order_type, label: '案件種別', as: :select, collection: ['社内テスト', '試食会', '本導入', 'イベント']
    end

    f.inputs '配送設定' do
      f.input :delivery_company, label: '配送会社'
      f.input :delivery_group, label: '配送グループ'
      f.input :delivery_priority, label: '配送優先順'
    end

    f.inputs '食数' do
      f.input :default_meal_count, label: 'デフォルト食数'
      f.input :confirmed_meal_count, label: '確定食数'
    end

    f.inputs 'ステータス' do
      f.input :status, label: 'ステータス', as: :select, collection: ['予定', '確定', '配送シート出力済', '完了']
      f.input :restaurant_status, label: '飲食店ステータス'
      f.input :delivery_company_status, label: '配送会社ステータス'
    end

    f.actions
  end

  show do
    attributes_table do
      row :scheduled_date
      row :company
      row :restaurant
      row :menu
      row :second_menu
      row :order_type
      row :delivery_company
      row :delivery_group
      row :delivery_priority
      row :default_meal_count
      row :confirmed_meal_count
      row :status
      row :restaurant_status
      row :delivery_company_status
      row :options
      row :created_at
      row :updated_at
    end
  end
end
