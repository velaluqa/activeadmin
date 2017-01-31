ActiveAdmin.register_page 'Dashboard' do
  menu(priority: 0, parent: 'immediate')

  content title: proc { I18n.t('active_admin.dashboard') } do
    render file: 'admin/dashboard/index'
  end

  controller do
    def authorize_access!
      # Permissions are handled internally.
      # The components retrieving report information take permissions
      # into account.
    end
  end

  page_action :save, method: :post do
    current_user.dashboard_configuration = {
      general: params[:config]
    }
    current_user.save
    render json: {}
  end

  action_item :edit_dashboard do
    link_to('Edit Dashboard', '#')
  end
  action_item :save_dashboard do
    link_to('Save Dashboard', '#')
  end
end
