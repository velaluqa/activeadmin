ActiveAdmin.register User do
  index do
    column :name do |user|
      link_to user.name, admin_user_path(user)
    end
    column :email
    default_actions
  end
end
