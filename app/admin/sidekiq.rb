ActiveAdmin.register_page 'Sidekiq' do
  menu(
    parent: 'admin',
    priority: 10,
    if: proc { authorized?(:manage, Sidekiq) }
  )

  content do
    content_tag(:iframe, '', src: '/sidekiq', class: 'sidekiq frame')
  end
end
