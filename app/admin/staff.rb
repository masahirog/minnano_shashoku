ActiveAdmin.register Staff do
  permit_params :name, :email, :role

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :role
    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :role
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :role
    end
    f.actions
  end
end
