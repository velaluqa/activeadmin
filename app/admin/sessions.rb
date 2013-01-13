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

    default_actions
  end

  show do |session|
    attributes_table do
      row :name
      row :study
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
    end
  end

  member_action :import_csv, :method => :post do
    @session = Session.find(params[:id])

    num_imported = Case.batch_create_from_csv(params[:session][:file].tempfile, @session, (@session.last_read_case.nil? ? 0 : @session.last_read_case.position+1))

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
