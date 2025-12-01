ActiveAdmin.register Menu do
  permit_params :restaurant_id, :name, :description, :price_per_meal, :is_active, :photo_url

  index do
    selectable_column
    id_column
    column :restaurant
    column :name
    column :price_per_meal
    column :is_active
    column :created_at
    actions
  end

  filter :restaurant
  filter :name
  filter :price_per_meal
  filter :is_active
  filter :created_at

  form do |f|
    f.inputs do
      f.input :restaurant, label: '飲食店'
      f.input :name, label: 'メニュー名'
      f.input :description, label: '説明', as: :text
      f.input :price_per_meal, label: '1食あたり価格'
      f.input :is_active, label: '有効'
      f.input :photo_url, label: '写真URL'
    end
    f.actions
  end

  show do
    attributes_table do
      row :restaurant
      row :name
      row :description
      row :price_per_meal
      row :is_active
      row :photo_url
      row :created_at
      row :updated_at
    end
  end
end
