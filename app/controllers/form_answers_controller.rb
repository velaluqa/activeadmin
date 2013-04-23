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
    
    answer.submitted_at = Time.now

    answer.save

    @case.state = :read
    @case.save
    
    if(@case.flag == :reader_testing)
      if(run_form_judgement_function(answer) == true)
        render :json => {:success => true}
      else
        render :json => {:success => false, :error => "You failed the reader testing.", :error_code => 3}, :status => :bad_request
      end
    else
      render :json => {:success => true}
    end
  end

  def run_form_judgement_function(form_answer)
    source = form_answer.form.components_at_version(form_answer.form_versions[form_answer.form.id])[:validators].first
    return false if source.nil?

    session_config = form_answer.session.configuration_at_version(form_answer.form_versions['session'])
    return false if (session_config.nil? or session_config['reader_testing'].nil?)

    # load utility libraries for usage in judgement functions via the sprockets environment
    underscore_source = Rails.application.assets.find_asset('underscore.js').source
    value_at_path_source = Rails.application.assets.find_asset('value_at_path.js').source

    js_context = ExecJS.compile(underscore_source+value_at_path_source+source)

    results_list = construct_results_list(form_answer.case)
    pp results_list

    result = js_context.call(session_config['reader_testing']['judgement_function'], results_list)

    return result
  end
  
  protected
  
  def construct_results_list(the_case)
    previous_cases = the_case.patient.cases.where('position <= ?', the_case.position).reject {|c| c.form_answer.nil?}

    previous_results = []
    previous_cases.each do |c|
      previous_results << {'answers' => c.form_answer.answers, 'images' => c.images}
    end

    return previous_results
  end
end
