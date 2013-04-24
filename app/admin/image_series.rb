ActiveAdmin.register ImageSeries do

  scope :all, :default => true
  scope :not_assigned

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :patient
    column :visit
    column :name
    
    default_actions
  end

  show do |image_series|
    attributes_table do
      row :patient
      row :visit
      row :name
      row :image_storage_path
      row 'Viewer' do
        link_to('View in Viewer', viewer_admin_image_series_path(image_series, :format => 'jnpl'))
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient
      f.input :visit
      f.input :name
    end

    f.buttons
  end

  # filters
  filter :patient
  filter :visit
  filter :name

  member_action :viewer, :method => :get do
    @image_series = ImageSeries.find(params[:id])

    @wado_query_urls = [wado_query_image_series_url(@image_series, :format => :xml)]

    render 'admin/shared/weasis_webstart.jnpl', :layout => false, :content_type => 'application/x-java-jnlp-file'
  end
end
