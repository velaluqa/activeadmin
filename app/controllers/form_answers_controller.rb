class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  def create    
    @case = Case.find(params['case_id'])
    if @case.nil?
      render :json => {:success => false, :error => 'The supplied case does not exist', :error_code => 1}, :status => :bad_request
    end

    authorize! :read, @case.session

    is_test_data = true
    if @case.session.validators.include?(current_user) and @case.session.state == :testing
      is_test_data = true
    elsif @case.session.readers.include?(current_user) and @case.session.state == :production
      is_test_data = false
    else
      render :json => {:success => false, :error => 'You are not authorized to submit answers for this case', :error_code => 1}
      return
    end

    answer = FormAnswer.new

    answer.form_id = params['form_id']
    answer.user_id = current_user.id

    answer.case_id = @case.id
    answer.session_id = @case.session.id
        
    answer.answers = params['answers']
    answer.answers_signature = params['answers_signature']

    answer.annotated_images = params['annotated_images']
    answer.annotated_images_signature = params['annotated_images_signature']
    
    answer.is_test_data = is_test_data

    answer.submitted_at = Time.now

    answer.save

    render :json => {:success => true}
  end
end
