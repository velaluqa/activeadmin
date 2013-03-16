require 'aa_customizable_default_actions'
require 'schema_validation'
require 'key_path_accessor'
require 'csv'
require 'set'

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
    if(params[:export_specification].nil? or params[:export_specification].tempfile.nil?)
      flash[:error] = 'You need to supply an export specification.'
      redirect_to :action => :index
      return
    end

    @errors = []
    @results = {}

    begin
      export_specification = YAML.load_file(params[:export_specification].tempfile)

      validator = SchemaValidation::ExportValidator.new
      @errors += validator.validate(export_specification)
    rescue SyntaxError => e
      @errors << e.message
    end

    return unless @errors.empty?

    case_ids = params[:cases].split(' ')      
    begin
      cases = Case.find(case_ids)
    rescue ActiveRecord::RecordNotFound => e
      @errors << e.message
    end
    return unless @errors.empty?

    cases.each do |c|
      unless(can? :manage, c)
        @results[c.id] = :unauthorized
        next
      end

      spec = export_specification[c.case_type]
      if(spec.nil?)
        @results[c.id] = :no_specification
        next
      end

      answers = (c.form_answer.nil? ? nil : c.form_answer.answers)
      if(answers.nil?)
        @results[c.id] = :no_answers
        next
      end

      c.exported_at = Time.now
      c.save

      @results[c.id] = []
      spec.each do |row_spec|
        if(row_spec['repeat'].nil?)
          repeat_array = nil
        else
          repeat_array = KeyPathAccessor::access_by_path(answers, row_spec['repeat'])
        end
        if(repeat_array.is_a?(Array))
          repeat_count = repeat_array.size
        else
          repeat_array = nil
          repeat_count = 1
        end

        repeat_count.times do |r|
          row = {}
          answers['_REPEAT'] = repeat_array[r] unless repeat_array.nil?

          row['ID'] = c.id if(row_spec['include_id'] == true)
          
          row_spec['values'].each do |name, path|
            value = KeyPathAccessor::access_by_path(answers, path)
            row[name] = value
          end

          @results[c.id] << row
        end
      end
    end

    case params[:export_format]
    when 'csv'
      @export_data = create_csv(@results)
      @export_suffix = 'csv'
    else
      @export_data = nil
      @errors << "Unknown export format '#{params[:export_format]}'"
    end

    send_data @export_data, :filename => "export.#{@export_suffix}" unless @export_data.nil?
    flash[:error] = 'Export failed'
  end

  controller do
    def create_csv(results)
      column_names = Set.new

      results.each do |case_id, rows|
        next unless rows.is_a?(Array)

        rows.each do |row|
          row.each do |name, value|
            column_names << name
          end
        end
      end

      column_names = column_names.to_a
      csv_table = CSV::Table.new([CSV::Row.new(column_names, column_names, true)])

      results.each do |case_id, rows|
        next unless rows.is_a?(Array)

        rows.each do |row|
          row_data = Array.new(column_names.size) do |i|
            row[column_names[i]]
          end
          
          csv_table << CSV::Row.new(column_names, row_data, false)
        end
      end

      return csv_table.to_csv
    end
  end


  batch_action :export do |selection|
    @page_title = 'Export'
    render 'admin/cases/export_settings', :locals => {:selection => selection}
  end

  batch_action :cancel, :confirmation => 'Canceling these Cases will set them as "unread" again. Make sure that no Reader is currently working on this session!' do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c

      case c.state
      when :in_progress
        c.state = :unread
      when :reopened_in_progress
        c.state = :reopened
      end

      c.save
    end

    redirect_to(:back, :notice => 'Selected cases have been canceled.')
  end
end
