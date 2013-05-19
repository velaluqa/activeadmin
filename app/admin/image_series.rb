require 'aa_domino'

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
    column :series_number
    column :name
    column :imaging_date
    column :images do |image_series|
      link_to(image_series.images.size, admin_images_path(:'q[image_series_id_eq]' => image_series.id))
    end
    
    default_actions
  end

  show do |image_series|
    attributes_table do
      row :patient
      row :visit
      row :series_number
      row :name
      domino_link_row(image_series)
      row :images do
        link_to(image_series.images.size, admin_images_path(:'q[image_series_id_eq]' => image_series.id))
      end
      row :image_storage_path
      row :imaging_date
      row 'Viewer' do
        link_to('View in Viewer', viewer_admin_image_series_path(image_series, :format => 'jnpl'))
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient
      f.input :visit
      f.input :series_number, :hint => (f.object.persisted? ? '' : 'Leave blank to automatically assign the next available series number.'), :required => f.object.persisted?
      f.input :name
      f.input :imaging_date, :as => :datepicker
    end

    f.buttons
  end

  # filters
  filter :patient
  filter :visit
  filter :series_number
  filter :name
  filter :imaging_date

  member_action :viewer, :method => :get do
    @image_series = ImageSeries.find(params[:id])

    current_user.ensure_authentication_token!
    @wado_query_urls = [wado_query_image_series_url(@image_series, :format => :xml, :authentication_token => current_user.authentication_token)]

    render 'admin/shared/weasis_webstart.jnpl', :layout => false, :content_type => 'application/x-java-jnlp-file'
  end

  viewer_cartable(:image_series)
end
