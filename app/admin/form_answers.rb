require 'key_path_accessor'

ActiveAdmin.register FormAnswer do
  before_filter { @skip_sidebar = true }

  actions :index, :show, :destroy #TEMP

  controller do
    helper :forms

    load_and_authorize_resource :except => :index
    def scoped_collection
      if session[:selected_study_id].nil?
        end_of_association_chain.accessible_by(current_ability)
      else
        study_session_ids = Study.find(session[:selected_study_id]).sessions.pluck(:id)
        end_of_association_chain.accessible_by(current_ability).in(session_id: study_session_ids)
      end
    end
  end

  index do
    selectable_column
    column :user
    column :session
    column :case
    column :form
    column 'Submission Date', :submitted_at
    column :signatures do |form_answer|
      if(form_answer.answers_signature_is_valid? && form_answer.annotated_images_signature_is_valid?)
        status_tag('Valid', :ok)
      else
        status_tag('Invalid', :error)
      end
    end
    column 'Test Data?', :is_test_data do |form_answer|
      if(form_answer.is_test_data)
        status_tag('Yes', :warning)
      else
        status_tag('No', :ok)
      end
    end
    column 'Obsolete?', :is_obsolete do |form_answer|
      if(form_answer.is_obsolete)
        status_tag('Yes', :warning)
      else
        status_tag('No', :ok)
      end
    end

    default_actions
  end

  show do |form_answer|
    attributes_table do
      row :user
      row :session
      row :case
      row :form
      row 'Configuration Versions' do
        ul do
          li {"Session: #{form_answer.form_versions['session']}"} unless form_answer.form_versions['session'].nil?
          form_answer.form_versions.each do |form_id, form_version|
            next if form_id == 'session'
            form_name = nil
            begin
              form = Form.find(form_id)
              form_name = form.name
            rescue ActiveRecord::RecordNotFound => e
              form_name = form_id.to_s
            end

            li {"Form #{form_name}: #{form_version}"}
          end
        end
      end
      row :submitted_at
      row :signatures do
        if(form_answer.answers_signature_is_valid? && form_answer.annotated_images_signature_is_valid?)
          status_tag('Valid', :ok)
        else
          status_tag('Invalid', :error)
        end
      end
      row 'Test Data?' do
        if(form_answer.is_test_data)
          status_tag('Yes', :warning)
        else
          status_tag('No', :ok)
        end
      end
      row 'Obsolete?' do
        if(form_answer.is_obsolete)
          status_tag('Yes', :warning)
        else
          status_tag('No', :ok)
        end
      end
      row :signature_public_key do
        if(form_answer.signature_public_key_id.blank? and form_answer.user.active_public_key.blank?)
          link_to('Download', download_public_key_admin_user_path(form_answer.user))
        elsif(form_answer.signature_public_key_id.blank?)
          link_to('Here', admin_public_key_path(form_answer.user.active_public_key))
        else
          link_to('Here', admin_public_key_path(form_answer.signature_public_key_id))
        end
      end
      row :answers do
        render "forms/results_table", :caption => '', :cases => [form_answer], :skip_header => true, :data_cleaning_buttons => (can? :manage, form_answer), :do_resolve_randomisation => true unless form_answer.answers.nil?
      end
      row :answers_raw do        
        CodeRay.scan(JSON::pretty_generate(form_answer.answers), :json).div(:css => :class).html_safe unless form_answer.answers.nil?
      end
      unless(form_answer.versions.nil? or form_answer.versions.empty?)
        row :previous_versions do
          render "admin/form_answers/previous_versions", :form_answer => form_answer, :do_resolve_randomisation => true
        end
      end
      row :annotated_images_raw do       
        CodeRay.scan(JSON::pretty_generate(form_answer.annotated_images), :json).div(:css => :class).html_safe unless form_answer.annotated_images.nil?
      end
      if(form_answer.case.flag == :reader_testing)
        row 'Reader Testing Judgement' do
          if(FormAnswersController.new.run_form_judgement_function(form_answer) == true)
            status_tag('Passed', :ok)
          else
            status_tag('Failed', :error)
          end
        end
      end
    end
  end

  batch_action :mark_as_obsolete do |selection|
    FormAnswer.find(selection).each do |f|
      authorize! :manage, f

      f.mark_obsolete()
    end

    redirect_to :action => :index
  end
  action_item :only => :show do
    link_to 'Mark obsolete', mark_obsolete_admin_form_answer_path(form_answer) if can? :manage, form_answer
  end
  member_action :mark_obsolete, :method => :get do
    @form_answer = FormAnswer.find(params[:id])
    authorize! :manage, @form_answer

    @form_answer.mark_obsolete()
    redirect_to({:action => :show}, :notice => "Form answer successfully marked as obsolete")
  end

  member_action :data_cleaning, :method => :post do
    @form_answer = FormAnswer.find(params[:id])
    authorize! :manage, @form_answer

    new_value = params[:cleaned_value]
    field_type = params[:field_type]
    field_id = params[:field_id]

    if(['fixed', 'group', 'section', 'calculated'].include?(field_type))
      flash[:error] = 'The chosen field type cannot be changed via the data cleaning tool.'
      redirect_to :action => :show
      return
    end

    case field_type
    when 'bool'
      new_value = (new_value == 'true')
    when 'number'
      new_value = new_value.to_f
    when 'select_multiple'
      new_value = new_value.split(',').map {|v| v.strip}
    when 'roi'
      new_value['location'] = JSON::parse(new_value['location'])
      new_value.each do |key, value|
        next if key == 'location'
        new_value[key] = value.to_f
      end
    end

    @form_answer.version_current_answers
    @form_answer.answers = KeyPathAccessor.set_by_path(@form_answer.answers, field_id, new_value)
    begin
      @form_answer.answers_signature = Base64.encode64(current_user.sign(FormAnswer::canonical_json(@form_answer.answers), params[:signature_password]))
      @form_answer.annotated_images_signature = Base64.encode64(current_user.sign(FormAnswer::canonical_json(@form_answer.annotated_images), params[:signature_password]))
    rescue OpenSSL::PKey::RSAError => e
      flash[:error] = 'Wrong signature password or invalid private key.'
      redirect_to :back
      return
    end

    @form_answer.submitted_at = Time.now
    @form_answer.signature_public_key_id = current_user.active_public_key.id

    @form_answer.save

    redirect_to :action => :show, :notice => 'The value was successfully changed.'
  end
  member_action :data_cleaning_form, :method => :get do
    @form_answer = FormAnswer.find(params[:id])
    @field_id = params[:field_id]

    authorize! :manage, @form_answer

    if(@field_id =~ /^(.*?)\[[0-9]*?\]\[(.*?)\]$/ or @field_id =~ /^(.*?)\[(.*?)\]$/)
      field_repeatable = $1
      field_sub_id = $2
    end

    @field_spec = if field_repeatable.blank?
                    @form_answer.form_fields_hash[0][@field_id]
                  else
                    @form_answer.form_fields_hash[1][field_repeatable][field_sub_id]
                  end
    pp @field_spec

    @field_value = KeyPathAccessor::access_by_path(@form_answer.answers, @field_id)    
    pp @field_value
    case @field_spec['type']
    when 'select_multiple'
      @field_value = @field_value.join(',')
    when 'bool'
      @field_value = (@field_value.nil? ? false : @field_value)
    end
    
    @page_title = 'Data Cleaning Tool - ' + @field_id
  end

  action_item :only => :show do
    link_to('Audit Trail', admin_mongoid_history_trackers_path(:audit_trail_view_type => 'form_answer', :audit_trail_view_id => resource.id))
  end
end
