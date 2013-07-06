ActiveAdmin.register_page 'Image Hierarchy' do

  menu :if => proc { Rails.env.development? }

  content do
    render 'content'
  end

  page_action :nodes, :method => :get do
    raw_node_id = params[:node]

    children_nodes = if(raw_node_id.blank?)
                       Study.accessible_by(current_ability).order('name asc').map {|s| {'label' => s.name, 'id' => 'study_'+s.id.to_s, 'load_on_demand' => true} }
                     elsif(raw_node_id =~ /^study_([0-9]*)$/)
                       Study.find($1).centers.accessible_by(current_ability).order('code asc').map {|c| {'label' => c.full_name, 'id' => 'center_'+c.id.to_s, 'load_on_demand' => true} }
                     elsif(raw_node_id =~ /^center_([0-9]*)$/)
                       Center.find($1).patients.accessible_by(current_ability).order('subject_id asc').map {|p| {'label' => p.name, 'id' => 'patient_'+p.id.to_s, 'load_on_demand' => true} }
                     elsif(raw_node_id =~ /^patient_([0-9]*)$/)
                       patient = Patient.find($1)

                       visit_nodes = patient.visits.accessible_by(current_ability).order('visit_number asc').map {|v| {'label' => v.name, 'id' => 'visit_'+v.id.to_s, 'load_on_demand' => true} }
                       visit_nodes << {'label' => 'Unassigned', 'id' => 'visit_unassigned_' + patient.id.to_s, 'load_on_demand' => true}

                       visit_nodes
                     elsif(raw_node_id =~ /^visit_([0-9]*)$/)
                       Visit.find($1).image_series.accessible_by(current_ability).order('imaging_date asc').map {|is| {'label' => is.imaging_date.to_s + ' - ' +is.name, 'id' => 'image_series_'+is.id.to_s} }
                     elsif(raw_node_id =~ /^visit_unassigned_([0-9]*)$/)
                       Patient.find($1).image_series.where(:visit_id => nil).accessible_by(current_ability).order('imaging_date asc').map {|is| {'label' => is.imaging_date.to_s + ' - ' +is.name, 'id' => 'image_series_'+is.id.to_s} }
                     else
                       []
                     end

    respond_to do |format|
      format.json { render :json => children_nodes }
    end
  end
end
