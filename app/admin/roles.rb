# coding: utf-8
ActiveAdmin.register Role do
  menu(
    parent: 'users',
    priority: 20
  )

  filter :title
  filter :user

  form partial: 'form'

  index do
    selectable_column
    column :title, sortable: :name do |role|
      link_to role.title, admin_role_path(role)
    end
    column 'Users' do |role|
      link_to "#{role.users.distinct.count} Users", admin_users_path(q: { user_roles_role_id_eq: role.id })
    end
    customizable_default_actions(current_ability)
  end

  show do |role|
    attributes_table do
      row :id
      row :title
      row :created_at
      row :updated_at
      row :users do
        link_to "#{role.users.distinct.count} Users", admin_users_path(q: { user_roles_role_id_eq: role.id })
      end
    end
    panel 'Permissions', class: 'permissions' do
      render partial: 'permissions_matrix', locals: { state: 'show', role: role, disabled: true }
    end
  end
end
