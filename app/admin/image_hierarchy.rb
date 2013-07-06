ActiveAdmin.register_page 'Image Hierarchy' do
  menu false

  content do
    div(:id => 'hierarchy_tree', :'data-url' => nodes_admin_image_hierarchy_path) do
      
    end
  end

  page_action :nodes, :method => :get do
    raw_node_id = params[:node_id]
    node = nil

    if(raw_node_id.blank?)
      node = :root
    elsif(raw_node_id =~ /^center_([0-9]*)$/)
      node_class = Center.find($1)
    elsif(raw_node_id =~ /^patient_([0-9]*)$/)
      node_class = Patient.find($1)
    elsif(raw_node_id =~ /^visit_([0-9]*)$/)
      node_class = Visit.find($1)
    end

    if(node.nil?)
      respond_to do |format|
        format.json { render :json => {'success' => false, 'data' => []} }
      end
      return
    end
  end
end
