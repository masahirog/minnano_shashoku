ActiveAdmin.register Driver do
  permit_params :delivery_company_id, :name, :phone, :is_active

  index do
    selectable_column
    id_column
    column :delivery_company
    column :name
    column :phone
    column :is_active
    column :created_at
    actions
  end

  filter :delivery_company
  filter :name
  filter :is_active
  filter :created_at

  form do |f|
    f.inputs do
      f.input :delivery_company, label: '配送会社'
      f.input :name, label: 'ドライバー名'
      f.input :phone, label: '電話番号'
      f.input :is_active, label: '有効'
    end
    f.actions
  end

  show do
    attributes_table do
      row :delivery_company
      row :name
      row :phone
      row :is_active
      row :created_at
      row :updated_at
    end
  end
end
