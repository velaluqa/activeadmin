ActiveAdmin.register Case do

  actions :index, :show, :destroy
  config.clear_action_items! # get rid of the default action items, since we have to handle 'delete' on a case-by-case basis

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :session
    column :position
    column :patient
    column :images
    column :case_type
    column :form_answer do |c|
      if(c.form_answer.nil?)
        status_tag('None', :error)
      else
        status_tag('available', :ok, :label => link_to('Available', admin_form_answer_path(c.form_answer)).html_safe)
      end
    end

    column '' do |resource|
      # most of this is copied from activeadmin/lib/active_admin/views/index_as_table.rb#default_actions
      # since we can't customize its behaviour
      links = ''.html_safe
      if controller.action_methods.include?('show')
        links << link_to(I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link")
      end
      if controller.action_methods.include?('edit')
        links << link_to(I18n.t('active_admin.edit'), edit_resource_path(resource), :class => "member_link edit_link")
      end
      if controller.action_methods.include?('destroy') and resource.form_answer.nil?
        links << link_to(I18n.t('active_admin.delete'), resource_path(resource), :method => :delete, :data => {:confirm => I18n.t('active_admin.delete_confirmation')}, :class => "member_link delete_link")
      end
      links
    end
  end

  show do |c|
    attributes_table do
      row :session
      row :position
      row :patient
      row :images
      row :case_type
      row :form_answers do
        if(c.form_answer.nil?)
          status_tag('None', :error)
        else
          status_tag('available', :ok, :label => link_to('Available', admin_form_answer_path(c.form_answer)).html_safe)
        end
      end
      row :case_data_raw do
        CodeRay.scan(JSON::pretty_generate(c.case_data.data), :json).div(:css => :class).html_safe unless c.case_data.nil?
      end
    end
  end

  action_item :only => :show do
    # copied from activeadmin/lib/active_admin/resource/action_items.rb#add_default_action_items
    if controller.action_methods.include?('destroy') and resource.form_answer.nil?
      link_to(I18n.t('active_admin.delete_model', :model => active_admin_config.resource_label),
              resource_path(resource),
              :method => :delete, :data => {:confirm => I18n.t('active_admin.delete_confirmation')})
    end
  end 
end
