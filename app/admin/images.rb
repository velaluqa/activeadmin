ActiveAdmin.register Image do

  actions :index, :show, :destroy

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :image_series
    column :id
    
    default_actions
  end

  show do |image|
    attributes_table do
      row :image_series
      row :id
      row :image_storage_path
      row 'File' do
        if(image.file_is_present?)
          status_tag('Present', :ok)
        else
          status_tag('Missing', :error)
        end
      end
    end
  end

  # filters
  filter :image_series
end
