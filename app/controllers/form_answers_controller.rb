require 'exceptions'

class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  # TEMP workaround, just to make doubly sure that #319 doesn't come round to bite us
  skip_before_filter :verify_authenticity_token, :only => :create

  def create   
    @case = Case.find(params['case_id'])
    if @case.nil?
      render :json => {:success => false, :error => 'The supplied case does not exist', :error_code => 1}, :status => :bad_request
      return
    end
    unless (@case.form_answer.nil? or @case.flag == :reader_testing or @case.state == :reopened_in_progress)
      render :json => {:success => false, :error => 'The supplied case was already answered', :error_code => 2}, :status => :bad_request
      return
    end

    is_test_data = true
    if @case.session.validators.include?(current_user) and @case.session.state == :testing
      is_test_data = true      
    elsif @case.session.readers.include?(current_user) and @case.session.state == :production
      is_test_data = false
    else
      render :json => {:success => false, :error => 'You are not authorized to submit answers for this case', :error_code => 1}, :status => :forbidden
      return
    end

    if @case.flag == :reader_testing
      @reader_testing_config_index = @case.form_answer.reader_testing_config_index
      @case.form_answer.destroy
      is_test_data = true
    end

    unless(@case.state == :reopened_in_progress and @case.form_answer)
      answer = FormAnswer.new

      answer.form_id = params['form_id']
      begin
        @form = @case.session.forms.find(params['form_id'])

        form_versions = {}
        form_versions[@form.id] = @form.locked_version

        form_versions['session'] = @case.session.locked_version

        @form.included_forms.each do |included_form_name|
          included_form = @case.session.forms.where(:name => included_form_name).first
          raise Exceptions::FormNotFoundError(included_form_name, @case) if included_form.nil?

          form_versions[included_form.id] = included_form.locked_version
        end

        answer.form_versions = form_versions
      rescue ActiveRecord::RecordNotFound => e
        render :json => {:success => false, :error => 'A form associated with this form answer does not exist: '+e.message, :error_code => 2}, :status => :bad_request
        return
      rescue Exceptions::FormNotFoundError => e
        render :json => {:success => false, :error => 'A form associated with this form answer does not exist: '+e.form_name, :error_code => 2}, :status => :bad_request
        return
      end
      answer.user_id = current_user.id

      answer.case_id = @case.id
      answer.session_id = @case.session.id

      answer.is_test_data = is_test_data
    else
      @case.form_answer.version_current_answers

      answer = @case.form_answer
    end

    answer.answers = params['answers']
    answer.answers_signature = params['answers_signature']

    answer.annotated_images = params['annotated_images']
    answer.annotated_images_signature = params['annotated_images_signature']

    answer.signature_public_key_id = (current_user.active_public_key.nil? ? nil : current_user.active_public_key.id)
    
    answer.submitted_at = Time.now
    answer.reader_testing_config_index = @reader_testing_config_index

    answer.adjudication_randomisation = {}
    if(@case.session)
      session_config = @case.session.locked_configuration

      if(session_config and session_config['type'] == 'adjudication' and session_config['adjudication'] and session_config['adjudication']['sessions'] and @case.case_data and @case.case_data.adjudication_data and @case.case_data.adjudication_data['assignment'])
        adjudication_assignment = @case.case_data.adjudication_data['assignment']
        
        session_config['adjudication']['sessions'].each_with_index do |session_id, index|
          assignment = adjudication_assignment[index].to_i

          answer.adjudication_randomisation[assignment] = session_id
        end
      end
    end
    
    answer.save

    @case.state = :read
    @case.current_reader = nil
    @case.save
    
    if(@case.flag == :reader_testing)
      if(answer.run_form_judgement_function() == true)
        render :json => {:success => true}
      else
        render :json => {:success => false, :error => "You failed the reader testing.", :error_code => 3}, :status => :bad_request
      end
    else
      render :json => {:success => true}
    end
  end
end
