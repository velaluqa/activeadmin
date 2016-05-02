ActiveAdmin.register_page 'Sidekiq' do
  menu url: '/sidekiq', if: proc { authorized?(:manage, Sidekiq) }
end
