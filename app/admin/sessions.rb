ActiveAdmin.register Session do

  index do
    selectable_column

    column :name do |session|
      link_to session.name, admin_session_path(session)
    end
    column :study
    column 'Reader', :user
    column 'Progress' do |session|
      "#{session.next_case_position} / #{session.case_list(false).size}"
    end
    column 'Most Recent Pause' do |session|
      most_recent_pause = session.most_recent_pause
      
      if most_recent_pause.nil?
        "None"
      else
        link_to most_recent_pause.end.to_s, admin_session_pause_path(most_recent_pause)
      end      
    end

    default_actions
  end

  member_action :import_csv, :method => :post do
    @session = Session.find(params[:id])

    num_imported = Case.batch_create_from_csv(params[:session][:file].tempfile, @session, @session.next_case_position)

    redirect_to({:action => :show}, :notice => "Successfully imported #{num_imported} cases from CSV")
  end
  member_action :import_csv_form, :method => :get do
    @session = Session.find(params[:id])

    render 'admin/sessions/import_csv_form'
  end
  action_item :only => :show do
    link_to 'Import CSV', import_csv_form_admin_session_path(session)
  end
  
end
