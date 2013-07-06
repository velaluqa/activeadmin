ActiveAdmin.register_page 'Image Hierarchy' do

  menu :if => proc { Rails.env.development? }

  content do
    render 'content'
  end

  page_action :nodes, :method => :get do
    raw_node_id = params[:node]

    children_nodes = if(raw_node_id.blank?)
                       Study.accessible_by(current_ability).order('name asc').map {|s| {'label' => view_context.link_to(s.name, admin_study_path(s), :target => '_blank').html_safe, 'id' => 'study_'+s.id.to_s, 'load_on_demand' => true} }
                     elsif(raw_node_id =~ /^study_([0-9]*)$/)
                       Study.find($1).centers.accessible_by(current_ability).order('code asc').map {|c| {'label' => view_context.link_to(c.full_name, admin_center_path(c), :target => '_blank').html_safe, 'id' => 'center_'+c.id.to_s, 'load_on_demand' => true} }
                     elsif(raw_node_id =~ /^center_([0-9]*)$/)
                       Center.find($1).patients.accessible_by(current_ability).order('subject_id asc').map {|p| {'label' => view_context.link_to(p.name, admin_patient_path(p), :target => '_blank').html_safe, 'id' => 'patient_'+p.id.to_s, 'load_on_demand' => true} }
                     elsif(raw_node_id =~ /^patient_([0-9]*)$/)
                       patient = Patient.find($1)

                       visit_nodes = patient.visits.accessible_by(current_ability).order('visit_number asc').map {|v| {'label' => view_context.link_to(v.name, admin_visit_path(v), :target => '_blank').html_safe, 'id' => 'visit_'+v.id.to_s, 'load_on_demand' => true} }
                       visit_nodes << {'label' => 'Unassigned', 'id' => 'visit_unassigned_' + patient.id.to_s, 'load_on_demand' => true}

                       visit_nodes
                     elsif(raw_node_id =~ /^visit_([0-9]*)$/)
                       Visit.find($1).image_series.accessible_by(current_ability).order('imaging_date asc').map {|is| {'label' => view_context.link_to(is.imaging_date.to_s + ' - ' +is.name, admin_image_series_path(is), :target => '_blank').html_safe, 'id' => 'image_series_'+is.id.to_s} }
                     elsif(raw_node_id =~ /^visit_unassigned_([0-9]*)$/)
                       Patient.find($1).image_series.where(:visit_id => nil).accessible_by(current_ability).order('imaging_date asc').map {|is| {'label' => view_context.link_to(is.imaging_date.to_s + ' - ' +is.name, admin_image_series_path(is), :target => '_blank').html_safe, 'id' => 'image_series_'+is.id.to_s} }
                     else
                       []
                     end

    respond_to do |format|
      format.json { render :json => children_nodes }
    end
  end
end
