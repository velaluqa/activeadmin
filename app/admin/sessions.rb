ActiveAdmin.register Session do

  index do
    selectable_column

    column :name do |session|
      link_to session.name, admin_session_path(session)
    end
    column :study
    column 'Readers' do |session|
      session.readers.size
    end
    column 'Validators' do |session|
      session.validators.size
    end
    column 'Progress' do |session|
      "#{session.case_list(:read).size} / #{session.case_list(:all).size}"
    end
    column :configuration do |session|
      if(session.configuration.nil?)
        status_tag('Missing', :error)
      else
        status_tag('Available', :ok)
      end
    end

    default_actions
  end

  show do |session|
    attributes_table do
      row :name
      row :study
      # TODO: remove, is just for testing
      row :rights do
        if(can? :validate, session and can? :blind_read, session)
          status_tag('Both', :error)
        elsif(can? :validate, session)
          status_tag('Validator', :ok)
        elsif(can? :blind_read, session)
          status_tag('Reader', :ok)
        else
          status_tag('None', :error)
        end
      end
      row :readers do
        if session.readers.empty?
          nil
        else
          render 'admin/sessions/list', :items => session.readers.map {|r| link_to(r.name, admin_user_path(r)) }
        end
      end
      row :validators do
        if session.validators.empty?
          nil
        else
          render 'admin/sessions/list', :items => session.validators.map {|v| link_to(v.name, admin_user_path(v)) }
        end
      end
      row :cases do
        if session.case_list(:all).empty?
          nil
        else
          render 'admin/sessions/list', :items => session.case_list(:all).map {|c| link_to(c.name, admin_case_path(c))}
        end
      end
      row :download_configuration do
        link_to 'Download Configuration', download_configuration_admin_session_path(session)
      end
      row :configuration do
        config = session.configuration
        if config.nil?
          nil
        else
          CodeRay.scan(JSON::pretty_generate(config), :json).div(:css => :class).html_safe
        end
      end
    end
  end

  member_action :import_case_list_csv, :method => :post do
    @session = Session.find(params[:id])

    num_imported = Case.batch_create_from_csv(params[:session][:file].tempfile, @session, @session.next_position)

    redirect_to({:action => :show}, :notice => "Successfully imported #{num_imported} cases from CSV")
  end
  member_action :import_case_list_csv_form, :method => :get do
    @session = Session.find(params[:id])

    @page_title = "Import Case List from CSV"
    render 'admin/sessions/import_csv_form', :locals => {:url => import_case_list_csv_admin_session_path}
  end
  action_item :only => :show do
    link_to 'Import Case List from CSV', import_case_list_csv_form_admin_session_path(session)
  end
  
  member_action :import_patient_data_csv, :method => :post do
    @session = Session.find(params[:id])

    num_imported = Patient.batch_create_from_csv(params[:session][:file].tempfile, @session)

    redirect_to({:action => :show}, :notice => "Successfully imported/updated #{num_imported} patients from CSV")
  end
  member_action :import_patient_data_csv_form, :method => :get do
    @session = Session.find(params[:id])

    @page_title = "Import Patient Data from CSV"
    render 'admin/sessions/import_csv_form', :locals => {:url => import_patient_data_csv_admin_session_path}
  end
  action_item :only => :show do
    link_to 'Import Patient Data from CSV', import_patient_data_csv_form_admin_session_path(session)
  end

  member_action :download_configuration do
    @session = Session.find(params[:id])

    send_file @session.config_file_path
  end
end
