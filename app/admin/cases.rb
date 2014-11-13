# -*- coding: utf-8 -*-
require 'aa_customizable_default_actions'
require 'aa_erica_comment'
require 'schema_validation'
require 'key_path_accessor'
require 'csv'
require 'set'

ActiveAdmin.register Case do

  menu if: proc { can? :read, Case }

  actions :index, :show, :edit, :update, :destroy
  config.clear_action_items! # get rid of the default action items, since we have to handle 'delete' on a case-by-case basis

  config.per_page = 100

  config.comments = false

  controller do
    load_and_authorize_resource :except => :index

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain.accessible_by(current_ability).includes(:patient => :center)
    end

    def generate_patients_options
      Study.all.map do |study|
        centers = study.centers.accessible_by(current_ability)
        
        centers_optgroups = centers.map do |center|
          patients = center.patients.accessible_by(current_ability)

          patient_options = patients.map do |patient|
            {:id => patient.id, :text => patient.subject_id}
          end

          {:id => "center_#{center.id.to_s}", :text => center.name, :children => patient_options}
        end

        {:id => "study_#{study.id.to_s}", :text => study.name, :children => centers_optgroups}
      end
    end
    def generate_patients_options_map(patients_options)
      patients_options_map = {}
      patients_options.each do |study|
        patients_options_map[study[:id]] = study[:text]
        study[:children].each do |center|
          patients_options_map[center[:id]] = center[:text]
          center[:children].each do |patient|
            patients_options_map[patient[:id]] = patient[:text]
          end
        end
      end

      patients_options_map
    end
    def generate_selected_patients
      selected_patients = []
      selected_patients += params[:q][:patient_id_in] unless(params[:q].nil? or params[:q][:patient_id_in].nil?)

      selected_patients += params[:q][:patient_center_id_in].map {|s_id| "center_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:patient_center_id_in].nil?)
      selected_patients += params[:q][:patient_center_study_id_in].map {|s_id| "study_#{s_id.to_s}"} unless(params[:q].nil? or params[:q][:patient_center_study_id_in].nil?)

      return selected_patients
    end

    def index
      if(params[:q] and params[:q][:patient_id_in] == [""])
        params[:q].delete(:patient_id_in)
      elsif(params[:q] and
         params[:q][:patient_id_in].respond_to?(:length) and
         params[:q][:patient_id_in].length == 1 and
         params[:q][:patient_id_in][0].include?(','))
        params[:q][:patient_id_in] = params[:q][:patient_id_in][0].split(',')
      end

      if(params[:q] and params[:q][:patient_id_in].respond_to?(:each)) 
        patient_id_in = []

        params[:q][:patient_id_in].each do |id|         
          if(id =~ /^center_([0-9]*)/)
            params[:q][:patient_center_id_in] ||= []
            params[:q][:patient_center_id_in] << $1
          elsif(id =~ /^study_([0-9]*)/)
            params[:q][:patient_center_study_id_in] ||= []
            params[:q][:patient_center_study_id_in] << $1
          else
            patient_id_in << id
          end
        end

        params[:q][:patient_id_in] = patient_id_in
      end
      pp params

      index!
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

  # this is a "fake" sidebar entry, which is only here to ensure that our data array for the advanced patient filter is rendered to the index page, even if it is empty
  # the resulting sidebar is hidden by the advanced filters javascript
  sidebar :advanced_filter_data, :only => :index do
    patients_select2_data = controller.generate_patients_options
    patients_options_map = controller.generate_patients_options_map(patients_select2_data)
    render :partial => 'admin/cases/advanced_filter_data', :locals => {:patients_select2_data => patients_select2_data, :patients_options_map => patients_options_map, :selected_patients => controller.generate_selected_patients}
  end
  
  index do
    selectable_column
    column :id
    column :session, :sortable => 'cases.session_id'
    column :position
    column :patient, :sortable => 'patients.subject_id' do |c|
      link_to(c.patient.subject_id, admin_patient_path(c.patient)) unless c.patient.nil?
    end
    column :images
    column :case_type
    column :flag, :sortable => :flag do |c|
      case c.flag
      when :regular
        status_tag('Regular', :ok)
      when :validation
        status_tag('Validation', :warning)
      when :reader_testing
        status_tag('Reader Testing', :warning)
      end
    end
    column :state, :sortable => :state do |c|
      case c.state
      when :unread
        status_tag('Unread', :error)
      when :in_progress
        status_tag('In Progress', :warning, :label => (c.current_reader.nil? ? 'In Progress' : ('In Progress: '+link_to(c.current_reader.name, admin_user_path(c.current_reader))).html_safe))
      when :read
        status_tag('Read', :ok, :label => link_to('Read', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
      when :reopened
        status_tag('Reopened', :warning, :label => link_to('Reopened', admin_form_answer_path(c.form_answer)).html_safe) unless c.form_answer.nil?
      when :reopened_in_progress
        status_tag('Reopened In Progress', :warning, :label => (link_to('Reopened & In Progress', admin_form_answer_path(c.form_answer)) + (c.current_reader.nil? ? '' : ': ' + link_to(c.current_reader.name, admin_user_path(c.current_reader)))).html_safe) unless c.form_answer.nil?
      when :postponed
        status_tag('Postponed', :warning)
      end
    end
    column 'Background', :sortable => :is_adjudication_background_case do |c|
      if c.is_adjudication_background_case
        status_tag('Yes', :error)
      else
        status_tag('No', :ok)
      end
    end
    column :reader do |c|
      if(c.form_answer.nil?)
        if(c.assigned_reader.nil?)
          link_to('Assign Reader', assign_reader_form_admin_cases_path(:return_url => request.fullpath, :selection => [c.id]))
        else
          ('Assigned to: '+link_to(c.assigned_reader.name, admin_user_path(c.assigned_reader)) + link_to(icon(:pen), assign_reader_form_admin_cases_path(:return_url => request.fullpath, :selection => [c.id]), :class => 'member_link')).html_safe
        end
      else
        link_to(c.form_answer.user.name, admin_user_path(c.form_answer.user))
      end
    end
    column 'Submission Date' do |c|
      pretty_format(c.form_answer.submitted_at) unless c.form_answer.nil?
    end
    column 'Last Export', :exported_at, :sortable => :exported_at do |c|
      if c.no_export
        status_tag('No Export')
      else
        pretty_format(c.exported_at) unless c.exported_at.nil?
      end
    end
    comment_column(:comment, 'Comment')
   
    customizable_default_actions do |resource|
      (resource.state == :unread and resource.form_answer.nil?) ? [] : [:edit, :destroy]
    end
  end

  show do |c|
    attributes_table do
      row :id
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
      row 'Background' do
        if c.is_adjudication_background_case
          status_tag('Yes', :error)
        else
          status_tag('No', :ok)
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
      row :assigned_reader
      row :exported_at do
        if c.no_export
          status_tag('No Export')
        else
          pretty_format(c.exported_at) unless c.exported_at.nil?
        end
      end
      comment_row(c, :comment, 'Comment')
      row :case_data_raw do
        CodeRay.scan(JSON::pretty_generate(c.case_data.data), :json).div(:css => :class).html_safe unless c.case_data.nil?
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :patient, :collection => f.object.session.study.all_patients
      f.input :images
      f.input :position
      f.input :case_type
      f.input :flag, :as => :radio, :collection => {'Regular' => :regular, 'Validation' => :validation}
      f.input :comment
    end
    
    f.buttons
  end

  csv do
    column :id
    column :session_id
    column ('Session Name') {|c| c.session.nil? ? nil : c.session.name}
    column :position
    column('Subject ID') {|c| c.patient.nil? ? '' : c.patient.subject_id}
    column :images
    column :case_type
    column :flag
    column :state
    column :is_adjudication_background_case
    column :exported_at
    column(:assigned_reader) {|c| (c.assigned_reader.nil? ? nil : c.assigned_reader.username)}
    column(:reader) {|c| (c.form_answer.nil? or c.form_answer.user.nil?) ? '' : c.form_answer.user.name }
    column(:submitted_at) {|c| c.form_answer.nil? ? '' : c.form_answer.submitted_at }
    column :comment
    column :created_at
  end

  # filters
  filter :id
  filter :patient, :collection => []
  filter :position
  filter :images
  filter :case_type
  filter :flag, :as => :check_boxes, :collection => Case::FLAG_SYMS.each_with_index.map {|flag, i| [flag, i]}
  filter :state, :as => :check_boxes, :collection => Case::STATE_SYMS.each_with_index.map {|state, i| [state, i]}
  filter :is_adjudication_background_case, :as => :select
  filter :assigned_reader, :as => :select
  filter :exported_at, :label => 'Last Export'
  filter :no_export, :as => :select
  filter :comment

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

  batch_action :move do |selection|
    session = nil
    selection.each do |case_id|
      c = Case.find(case_id)
      if session.nil?
        session = c.session
      elsif session != c.session
        flash[:error] = 'All cases for a move must belong to the same session.'
        redirect_to :back
        return
      end
    end
    authorize! :manage, session

    @page_title = 'Move selected Cases'
    render 'admin/cases/move_settings', :locals => {:return_url => request.referer, :selection => selection, :cases => session.cases.where('id NOT IN (?)', selection).order(:position)}
  end
  collection_action :batch_move, :method => :post do
    # identify starting position
    insert_after_case = Case.find(params[:new_position])
    pp insert_after_case
    authorize! :manage, insert_after_case.session

    moved_cases = Case.find(params[:cases].split(' ')).sort {|a,b| a.position <=> b.position}
    pp moved_cases
    later_cases = insert_after_case.session.cases.where('id NOT IN (?) and position > ?', params[:cases].split(' '), insert_after_case.position).order(:position)
    pp later_cases

    next_position = insert_after_case.position + 1
    next_free_position = insert_after_case.session.next_position
    (moved_cases + later_cases).each do |c|
      c.position = next_free_position
      c.save
      next_free_position += 1
    end
    next_position = insert_after_case.position + 1
    (moved_cases + later_cases).each do |c|
      c.position = next_position
      c.save
      next_position += 1
    end

    flash[:notice] = "#{moved_cases.size} cases moved to after #{insert_after_case.name}"
    if(params[:return_url].blank?)
      redirect_to :action => :index
    else
      redirect_to params[:return_url]
    end
  end

  batch_action :mark_as_regular do |selection|
    Case.find(selection).each do |c|
      authorize! :manage, c
      next unless (c.state == :unread and c.form_answer.nil?)

      c.flag = :regular
      c.save
    end

    redirect_to :back
  end
  batch_action :mark_as_validation do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c
      next unless (c.state == :unread and c.form_answer.nil?)

      c.flag = :validation
      c.save
    end

    redirect_to :back
  end

  batch_action :mark_as_background do |selection|
    Case.find(selection).each do |c|
      authorize! :manage, c
      next unless (c.state == :unread and c.form_answer.nil?)

      c.is_adjudication_background_case = true
      c.save
    end

    redirect_to :back
  end
  batch_action :mark_as_not_background do |selection|
    Case.find(selection).each do |c|
      authorize! :manage, c
      next unless (c.state == :unread and c.form_answer.nil?)

      c.is_adjudication_background_case = false
      c.save
    end

    redirect_to :back
  end

  batch_action :mark_as_no_export do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c

      c.no_export = true
      c.save
    end

    redirect_to :back, :notice => 'Cases were marked as not exportable.'
  end
  batch_action :reset_no_export do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c

      c.no_export = false
      c.save
    end

    redirect_to :back, :notice => 'Cases were marked as exportable.'
  end

  collection_action :batch_export, :method => :post do
    if(params[:export_specification].nil? or params[:export_specification].tempfile.nil?)
      flash[:error] = 'You need to supply an export specification.'
      if(params[:return_url].blank?)
        redirect_to :action => :index
      else
        redirect_to params[:return_url]
      end
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

      if(c.no_export == true)
        @results[c.id] = :no_export
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
          repeat_count = 1
        else
          repeat_array = KeyPathAccessor::access_by_path(answers, row_spec['repeat'])
          repeat_count = (repeat_array.is_a?(Array) ? repeat_array.size : 0)
        end

        answers = answers.merge(c.data_hash)

        repeat_count.times do |r|
          row = {}
          answers['_REPEAT'] = repeat_array[r].merge({'_ID' => (r+1), '_REPEATABLE_ID' => row_spec['repeat']}) unless repeat_array.nil?

          row['ID'] = c.id if(row_spec['include_id'] == true)
          
          row_spec['values'].each do |name, path|
            if(path =~ /^_TEXT\[(.*)\]$/)
              value = $1
            else
              value = KeyPathAccessor::access_by_path(answers, path)

              value = value.join(',') if value.is_a?(Array)
            end
            
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
    render 'admin/cases/export_settings', :locals => {:selection => selection, :return_url => request.referer}
  end

  batch_action :cancel, :confirm => 'Canceling these Cases will set them as "unread" again. Make sure that no Reader is currently working on this session!' do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c

      case c.state
      when :in_progress
        c.state = :unread
      when :reopened_in_progress
        c.state = :reopened
      end

      c.current_reader = nil
      c.save
    end

    redirect_to(:back, :notice => 'Selected cases have been canceled.')
  end

  batch_action :postpone do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c
      next unless c.state == :unread

      c.state = :postponed
      c.save
    end

    redirect_to(:back, :notice => 'Selected cases have been postponed.')
  end
  batch_action :unpostpone do |selection|
    Case.find(selection).each do |c|
      next unless can? :manage, c
      next unless c.state == :postponed

      c.state = :unread
      c.save
    end

    redirect_to(:back, :notice => 'Selected cases have been "unpostponed".')
  end

  erica_commentable(:comment, 'Comment')

  collection_action :assign_reader, :method => :post do
    @cases = Case.find(params[:selection])

    @cases.each do |c|
      authorize! :manage, c

      c.assigned_reader_id = params[:case][:assigned_reader_id]
      c.save
    end

    if(params[:return_url].blank?)
      redirect_to :action => :index, :notice => 'Reader assigned.'
    else
      redirect_to params[:return_url], :notice => 'Reader assigned.'
    end
  end
  collection_action :assign_reader_form, :method => :get do
    if(params[:selection].blank?)
      flash[:error] = 'You must select at least on case.'
      redirect_to (paramſ[:return_url].blank? ? :back : params[:return_url])
      return
    end

    @selection = params[:selection]
    @cases = Case.find(params[:selection])

    session_id = nil
    @cases.each do |c|
      authorize! :manage, c

      session_id ||= c.session_id
      if(session_id != c.session_id)
        flash[:error] = 'All cases must be from the same session.'
        redirect_to (paramſ[:return_url].blank? ? :back : params[:return_url])
        return
      end
    end

    @return_url = (params[:return_url].blank? ? request.referer : params[:return_url])
    @page_title = 'Assign Reader'    
  end
  batch_action :batch_assign_reader do |selection|
    redirect_to assign_reader_form_admin_cases_path(:selection => selection, :return_url => request.referer)
  end

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'case', :audit_trail_view_id => resource.id))
  end
end
