ActiveAdmin.register Company do
  permit_params :name, :formal_name, :contract_status, :staff_id,
                :contact_person, :contact_phone, :contact_email, :delivery_address,
                :billing_email, :billing_dept, :billing_person_title, :billing_person_name,
                :default_meal_count, :paypay_enabled, :paypay_employee_rate_1, :paypay_employee_rate_2,
                :discount_type, :discount_amount, :initial_fee_waived

  index do
    selectable_column
    id_column
    column :name
    column :formal_name
    column :contract_status
    column :default_meal_count
    column :staff
    column :created_at
    actions
  end

  filter :name
  filter :formal_name
  filter :contract_status
  filter :staff
  filter :created_at

  form do |f|
    f.inputs '基本情報' do
      f.input :name, label: '通称'
      f.input :formal_name, label: '正式名称'
      f.input :contract_status, label: '契約ステータス'
      f.input :staff, label: '担当スタッフ'
    end

    f.inputs 'クライアント情報' do
      f.input :contact_person, label: '担当者名'
      f.input :contact_phone, label: '電話番号'
      f.input :contact_email, label: 'メールアドレス'
      f.input :delivery_address, label: '配送先住所', as: :text
    end

    f.inputs '請求情報' do
      f.input :billing_email, label: '請求先メール'
      f.input :billing_dept, label: '請求先部署'
      f.input :billing_person_title, label: '請求先役職'
      f.input :billing_person_name, label: '請求先氏名'
    end

    f.inputs '設定' do
      f.input :default_meal_count, label: 'デフォルト食数'
    end

    f.inputs 'PayPay設定' do
      f.input :paypay_enabled, label: 'PayPay有効'
      f.input :paypay_employee_rate_1, label: 'PayPay従業員負担額1'
      f.input :paypay_employee_rate_2, label: 'PayPay従業員負担額2'
    end

    f.inputs '割引設定' do
      f.input :discount_type, label: '割引種別'
      f.input :discount_amount, label: '割引額'
      f.input :initial_fee_waived, label: '初期費用免除'
    end

    f.actions
  end

  show do
    attributes_table do
      row :name
      row :formal_name
      row :contract_status
      row :staff
      row :contact_person
      row :contact_phone
      row :contact_email
      row :delivery_address
      row :billing_email
      row :billing_dept
      row :billing_person_title
      row :billing_person_name
      row :default_meal_count
      row :paypay_enabled
      row :paypay_employee_rate_1
      row :paypay_employee_rate_2
      row :discount_type
      row :discount_amount
      row :initial_fee_waived
      row :created_at
      row :updated_at
    end
  end
end
