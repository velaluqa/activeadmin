ActiveAdmin.register_page 'Sidekiq' do
  menu if: proc { authorized?(:manage, Sidekiq) }

  content do
    content_tag(:iframe, '', src: '/sidekiq', class: 'sidekiq frame')
  end
end
