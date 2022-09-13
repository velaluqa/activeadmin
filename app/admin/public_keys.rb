ActiveAdmin.register PublicKey do
  decorate_with(PublicKeyDecorator)

  menu false
  config.comments = false

  actions :index, :show

  controller do
    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain
    end
  end

  index do
    selectable_column
    column :user, sortable: :user_id
    column :status, sortable: :deactivated_at 
    column :public_key 

    actions
  end

  show do |public_key|
    attributes_table do
      row :user
      row :status 
      row :public_key
    end
  end

  # filters
  filter :user
  filter :active, as: :select
  filter :deactivated_at

  member_action :download, method: :get do
    @public_key = PublicKey.find(params[:id])
    authorize! :read, @public_key

    if @public_key.public_key.nil?
      flash[:error] = 'The public key is not present.'
      redirect_back(fallback_location: admin_public_key_path(id: params[:id]))
    else
      send_data @public_key.public_key, filename: @public_key.user.username + '_' + (@public_key.deactivated_at.nil? ? 'active' : @public_key.deactivated_at.strftime('%FT%R')) + '.pub'
    end
  end
end
