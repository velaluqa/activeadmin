ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: -> { I18n.t('active_admin.dashboard') }

  content title: -> { I18n.t('active_admin.dashboard') } do
    render file: 'admin/dashboard/index'
  end
end
