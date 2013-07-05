ActiveAdmin.register_page 'Sidekiq' do
  menu url: '/sidekiq', if: proc {current_user.is_app_admin?}
end
