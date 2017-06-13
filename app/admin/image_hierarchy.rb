ActiveAdmin.register_page 'Image Hierarchy' do
  menu(
    parent: 'meta_store',
    priority: 20,
    if: lambda do
      authorized?(:read, Study) &&
      authorized?(:read, Center) &&
      authorized?(:read, Patient) &&
      authorized?(:read, Visit) &&
      authorized?(:read, ImageSeries)
    end
  )

  content do
    render 'content'
  end

  controller do
    def visit_css_class(visit)
      'status_tag ' + case visit.state_sym
                      when :incomplete then ''
                      when :complete then 'warning'
                      when :mqc_issues then 'error'
                      when :mqc_passed then 'ok'
                      else ''
                     end
    end

    def image_series_css_class(is)
      'status_tag ' + case is.state
                      when :imported then 'error'
                      when :visit_assigned then 'warning'
                      when :required_series_assigned then 'ok'
                      else ''
                     end
    end

    def required_series_css_class(rs)
      'status_tag ' + case rs.tqc_state
                      when 'pending' then 'warning'
                      when 'issues' then 'error'
                      when 'passed' then 'ok'
                      else ''
                     end
    end

    def authorize_access!
      authorize!(:read, Study)
      authorize!(:read, Center)
      authorize!(:read, Patient)
      authorize!(:read, Visit)
      authorize!(:read, ImageSeries)
    end
  end

  # TODO: Refactor with jbuilder
  page_action :nodes, method: :get do
    raw_node_id = params[:node]

    children_nodes = if raw_node_id.blank?
                       (session[:selected_study_id].blank? ? Study : Study.where(id: session[:selected_study_id])).accessible_by(current_ability).order('name asc').map { |s| { 'label' => view_context.link_to(s.name, admin_study_path(s), target: '_blank').html_safe, 'id' => 'study_' + s.id.to_s, 'load_on_demand' => true } }
                     elsif raw_node_id =~ /^study_([0-9]*)$/
                       Study.find(Regexp.last_match(1)).centers.accessible_by(current_ability).order('code asc').map { |c| { 'label' => view_context.link_to(c.full_name, admin_center_path(c), target: '_blank').html_safe, 'id' => 'center_' + c.id.to_s, 'load_on_demand' => true } }
                     elsif raw_node_id =~ /^center_([0-9]*)$/
                       Center.find(Regexp.last_match(1)).patients.accessible_by(current_ability).order('subject_id asc').map { |p| { 'label' => view_context.link_to(p.name, admin_patient_path(p), target: '_blank').html_safe, 'id' => 'patient_' + p.id.to_s, 'load_on_demand' => true } }
                     elsif raw_node_id =~ /^patient_([0-9]*)$/
                       patient = Patient.find(Regexp.last_match(1))

                       visit_nodes = patient.visits.accessible_by(current_ability).order('visit_number asc').map { |v| { 'label' => view_context.link_to(v.name, admin_visit_path(v), target: '_blank', class: visit_css_class(v)).html_safe, 'id' => 'visit_' + v.id.to_s, 'load_on_demand' => true } }
                       visit_nodes << { 'label' => 'Unassigned', 'id' => 'visit_unassigned_' + patient.id.to_s, 'load_on_demand' => true }

                       visit_nodes
                     elsif raw_node_id =~ /^visit_([0-9]*)$/
                       Visit.find(Regexp.last_match(1)).image_series.accessible_by(current_ability).order('imaging_date asc').map { |is| { 'label' => view_context.link_to(is.imaging_date.to_s + ' - ' + is.name, admin_image_series_path(is), target: '_blank', class: image_series_css_class(is)).html_safe, 'id' => 'image_series_' + is.id.to_s } } + [{ 'label' => 'Required Series', 'id' => 'visit_required_series_' + Regexp.last_match(1).to_s, 'load_on_demand' => true }]
                     elsif raw_node_id =~ /^visit_unassigned_([0-9]*)$/
                       Patient.find(Regexp.last_match(1)).image_series.where(visit_id: nil).accessible_by(current_ability).order('imaging_date asc').map { |is| { 'label' => view_context.link_to(is.imaging_date.to_s + ' - ' + is.name, admin_image_series_path(is), target: '_blank', class: image_series_css_class(is)).html_safe, 'id' => 'image_series_' + is.id.to_s } }
                     elsif raw_node_id =~ /^visit_required_series_([0-9]*)$/
                       Visit.find(Regexp.last_match(1)).required_series_objects.map { |rs| { 'label' => (rs.assigned? ? view_context.link_to(rs.name + ' -> ' + rs.assigned_image_series.imaging_date.to_s + ' - ' + rs.assigned_image_series.name, admin_image_series_path(rs.assigned_image_series), target: '_blank', class: required_series_css_class(rs)).html_safe : rs.name), 'id' => 'visit_required_series_' + Regexp.last_match(1).to_s + '_' + rs.name } }
                     else
                       []
                     end

    respond_to do |format|
      format.json { render json: children_nodes }
    end
  end
end
