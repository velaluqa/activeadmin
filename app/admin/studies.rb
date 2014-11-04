ActiveAdmin.register Study do

  menu if: Proc.new {can? :read, Study}

  controller do
    load_and_authorize_resource :except => :index
    skip_load_and_authorize_resource :only => [:select_for_session, :selected_study, :deselect_study]

    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column

    column :name, :sortable => :name do |study|
      link_to study.name, admin_study_path(study)
    end
    column 'Select for Session' do |study|
      link_to('Select', select_for_session_admin_study_path(study))
    end
    
    default_actions
  end

  show do |study|
    attributes_table do
      row :name
    end
  end
  
  form do |f|
    f.inputs 'Details' do
      f.input :name, :required => true
    end

    f.buttons
  end

  # filters
  filter :name

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'study', :audit_trail_view_id => resource.id))
  end

  member_action :select_for_session, :method => :get do
    @study = Study.find(params[:id])
    authorize! :read, @study
    
    session[:selected_study_id] = @study.id
    session[:selected_study_name] = @study.name

    redirect_to :back, :notice => "Study #{@study.name} was selected for this session."
  end
  action_item :only => :show do
    link_to('Select for Session', select_for_session_admin_study_path(resource))
  end
  collection_action :selected_study, :method => :get do
    if(session[:selected_study_id].nil?)
      flash[:error] = 'No study selected for current session.'
      redirect_to(admin_studies_path)
    else
      redirect_to(admin_study_path(session[:selected_study_id]))
    end
  end
  collection_action :deselect_study, :method => :get do
    if(session[:selected_study_id].nil?)
      flash[:error] = 'No study selected for current session.'
      redirect_to :back
    else
      session[:selected_study_id] = nil
      session[:selected_study_name] = nil
      redirect_to :back, :notice => 'The study was deselected for the current session.'
    end
  end
  action_item :only => :index do
    link_to('Deselect Study', deselect_study_admin_studies_path) unless session[:selected_study_id].nil?
  end
end
