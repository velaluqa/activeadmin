ActiveAdmin.register_page 'Help' do
  content do
    render partial: 'index'
  end

  controller do
    def authorize_access!
    end

    helper :help
  end

  Dir[Rails.root.join('app/views/admin/help/*.md')].each do |help_page|
    name = File.basename(help_page, '.*')
    next if name[0] == '_'
    page_action name.to_sym, method: :get do
      render(
        file: 'app/views/admin/help/_document',
        locals: { document: name.to_sym },
        layout: true
      )
    end
  end
end
