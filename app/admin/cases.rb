require 'aa_customizable_default_actions'

ActiveAdmin.register Case do

  actions :index, :show, :edit, :update, :destroy
  config.clear_action_items! # get rid of the default action items, since we have to handle 'delete' on a case-by-case basis

  controller do
    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end

    def update
      c = Case.find(params[:id])
      unless c.state == :unread and c.form_answer.nil?
        flash[:error] = 'You are not authorized to edit this case!'
        redirect_to :action => :show
        return
      end
      
      authorize! :manage, c
      update!
    end
  end

  index do
    selectable_column
    column :session
    column :position
    column :patient
    column :images
    column :case_type
    column :flag do |c|
      case c.flag
      when :regular
        status_tag('Regular', :ok)
      when :validation
        status_tag('Validation', :warning)
      when :reader_testing
        status_tag('Reader Testing', :warning)
      end
    end
    column :state do |c|
      case c.state
      when :unread
        status_tag('Unread', :error)
      when :in_progress
        status_tag('In Progress', :warning)
      when :read
        status_tag('Read', :ok, :label => link_to('Read', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
      when :reopened
        status_tag('Reopened', :warning, :label => link_to('Reopened', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
      when :reopened_in_progress
        status_tag('Reopened In Progress', :warning, :label => link_to('Reopened & In Progress', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
      end
    end
    column 'Last Export', :exported_at
   
    customizable_default_actions do |resource|
      (resource.state == :unread and resource.form_answer.nil?) ? [] : [:edit, :destroy]
    end
  end

  show do |c|
    attributes_table do
      row :session
      row :position
      row :patient
      row :images
      row :case_type
      row :flag do
        case c.flag
        when :regular
          status_tag('Regular', :ok)
        when :validation
          status_tag('Validation', :warning)
        when :reader_testing
          status_tag('Reader Testing', :warning)
        end
      end
      row :state do
        case c.state
        when :unread
          status_tag('Unread', :error)
        when :in_progress
          status_tag('In Progress', :warning)
        when :read
          status_tag('Read', :ok, :label => link_to('Read', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
        when :reopened
          status_tag('Reopened', :warning, :label => link_to('Reopened', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
        when :reopened_in_progress
          status_tag('Reopened In Progress', :warning, :label => link_to('Reopened & In Progress', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
        end
      end
      row :exported_at
      row :case_data_raw do
        CodeRay.scan(JSON::pretty_generate(c.case_data.data), :json).div(:css => :class).html_safe unless c.case_data.nil?
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient, :collection => f.object.session.patients
      f.input :images
      f.input :position
      f.input :case_type
      f.input :flag, :as => :radio, :collection => {'Regular' => :regular, 'Validation' => :validation}
    end
    
    f.buttons
  end

  member_action :reopen, :only => :show do
    @case = Case.find(params[:id])

    if(@case.state != :read or @case.form_answer.nil?)
      flash[:error] = 'Only read cases can be reopened.'
      redirect_to :action => :show
      return
    end

    @case.state = :reopened
    @case.save

    redirect_to({:action => :show}, :notice => 'Case is reopened and the answers can now be ammended via the Reader Client.')
  end
  action_item :only => :show do
    link_to('Reopen', reopen_admin_case_path(resource)) if (resource.state == :read and resource.form_answer)
  end

  action_item :only => :show do
    # copied from activeadmin/lib/active_admin/resource/action_items.rb#add_default_action_items
    if controller.action_methods.include?('edit') and resource.state == :unread and resource.form_answer.nil?
      link_to(I18n.t('active_admin.edit_model', :model => active_admin_config.resource_label), edit_resource_path(resource))
    end
  end
  action_item :only => :show do
    # copied from activeadmin/lib/active_admin/resource/action_items.rb#add_default_action_items
    if controller.action_methods.include?('destroy') and resource.state == :unread and resource.form_answer.nil?
      link_to(I18n.t('active_admin.delete_model', :model => active_admin_config.resource_label),
              resource_path(resource),
              :method => :delete, :data => {:confirm => I18n.t('active_admin.delete_confirmation')})
    end
  end 

  batch_action :mark_as_regular do |selection|
    Case.find(selection).each do |c|
      authorize! :manage, c
      next unless (c.state == :unread and c.form_answer.nil?)

      c.flag = :regular
      c.save
    end

    redirect_to :action => :index
  end
  batch_action :mark_as_validation do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c
      next unless (c.state == :unread and c.form_answer.nil?)

      c.flag = :validation
      c.save
    end

    redirect_to :action => :index
  end

  collection_action :batch_export, :method => :post do
    pp params
  end

  # batch_action :export do |selection|
  #   @page_title = 'Export'
  #   render 'admin/cases/export_settings', :locals => {:selection => selection}
  # end
end
