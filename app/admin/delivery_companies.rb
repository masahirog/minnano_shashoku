ActiveAdmin.register DeliveryCompany do
  permit_params :name, :contact_person, :phone, :email, :is_active

  index do
    selectable_column
    id_column
    column :name
    column :contact_person
    column :phone
    column :email
    column :is_active
    column :created_at
    actions
  end

  filter :name
  filter :contact_person
  filter :is_active
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name, label: '配送会社名'
      f.input :contact_person, label: '担当者名'
      f.input :phone, label: '電話番号'
      f.input :email, label: 'メールアドレス'
      f.input :is_active, label: '有効'
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :contact_person
      row :phone
      row :email
      row :is_active
      row :created_at
      row :updated_at
    end

    panel 'ドライバー' do
      table_for delivery_company.drivers do
        column :name
        column :phone
        column :is_active
        column :actions do |driver|
          link_to '詳細', admin_driver_path(driver)
        end
      end
    end
  end
end
