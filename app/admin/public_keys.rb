ActiveAdmin.register PublicKey do
  menu false
  config.comments = false

  actions :index, :show

  controller do
    load_and_authorize_resource :except => :index

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :user, :sortable => :user_id
    column :status, :sortable => :deactivated_at do |public_key|
      if public_key.active?
        status_tag('Active', :ok)
      else
        status_tag('Deactivated', nil, :label => 'Deactivated at '+pretty_format(public_key.deactivated_at))
      end
    end
    column :public_key do |public_key|
      link_to('Download', download_admin_public_key_path(public_key))
    end

    default_actions
  end

  show do |public_key|
    attributes_table do
      row :user
      row :status do
        if public_key.active?
          status_tag('Active', :ok)
        else
          status_tag('Deactivated', nil, :label => 'Deactivated at '+pretty_format(public_key.deactivated_at))
        end
      end
      row :public_key do
        link_to('Download', download_admin_public_key_path(public_key))
      end
    end
  end

  # filters
  filter :user
  filter :active, :as => :select
  filter :deactivated_at

  member_action :download, :method => :get do
    @public_key = PublicKey.find(params[:id])
    authorize! :read, @public_key
    
    if(@public_key.public_key.nil?)
      flash[:error] = 'The public key is not present.'
      redirect_to :back
    else
      send_data @public_key.public_key, :filename => @public_key.user.username + '_' + (@public_key.deactivated_at.nil? ? 'active' : @public_key.deactivated_at.strftime('%FT%R')) + '.pub'
    end
  end
end
