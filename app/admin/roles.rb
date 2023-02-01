# coding: utf-8

ActiveAdmin.register Role do
  menu(
    parent: 'users',
    priority: 20
  )

  filter :title
  filter :user

  form partial: 'form'

  permit_params(:title, :abilities)

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

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'role',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
