ActiveAdmin.register Restaurant do
  permit_params :name, :staff_id, :supplier_code, :invoice_number, :contract_status, :genre,
                :phone, :contact_person, :contact_phone, :contact_email,
                :max_capacity, :pickup_time_with_main, :pickup_time_trial_only, :pickup_address,
                :has_delivery_fee, :delivery_fee_per_meal, :self_delivery, :trial_available,
                closed_days: []

  index do
    selectable_column
    id_column
    column :name
    column :genre
    column :contract_status
    column :max_capacity
    column :pickup_time_with_main
    column :pickup_time_trial_only
    column :staff
    column :created_at
    actions
  end

  filter :name
  filter :genre
  filter :contract_status
  filter :staff
  filter :created_at

  form do |f|
    f.inputs '基本情報' do
      f.input :name, label: '飲食店名'
      f.input :staff, label: '担当スタッフ'
      f.input :supplier_code, label: '送付先コード'
      f.input :invoice_number, label: 'インボイス番号'
      f.input :contract_status, label: '契約ステータス'
      f.input :genre, label: 'ジャンル'
    end

    f.inputs '連絡先' do
      f.input :phone, label: '電話番号'
      f.input :contact_person, label: '担当者名'
      f.input :contact_phone, label: '担当者電話'
      f.input :contact_email, label: '担当者メール'
    end

    f.inputs '配送設定' do
      f.input :max_capacity, label: '対応可能食数'
      f.input :pickup_time_with_main, label: '集荷時刻（本導入あり）'
      f.input :pickup_time_trial_only, label: '集荷時刻（試食会のみ）'
      f.input :pickup_address, label: '集荷先住所', as: :text
      f.input :closed_days, label: '定休日', as: :check_boxes, collection: %w[月 火 水 木 金 土 日]
    end

    f.inputs '特殊設定' do
      f.input :has_delivery_fee, label: '配送料発生'
      f.input :delivery_fee_per_meal, label: '配送料（1食あたり）'
      f.input :self_delivery, label: '自社配送'
      f.input :trial_available, label: '試食会対応可能'
    end

    f.actions
  end

  show do
    attributes_table do
      row :name
      row :staff
      row :supplier_code
      row :invoice_number
      row :contract_status
      row :genre
      row :phone
      row :contact_person
      row :contact_phone
      row :contact_email
      row :max_capacity
      row :pickup_time_with_main
      row :pickup_time_trial_only
      row :pickup_address
      row :closed_days
      row :has_delivery_fee
      row :delivery_fee_per_meal
      row :self_delivery
      row :trial_available
      row :created_at
      row :updated_at
    end

    panel 'メニュー' do
      table_for restaurant.menus do
        column :name
        column :price_per_meal
        column :is_active
        column :actions do |menu|
          link_to '詳細', admin_menu_path(menu)
        end
      end
    end
  end
end
