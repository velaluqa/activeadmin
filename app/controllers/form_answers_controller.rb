class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  def create    
    @case = Case.find(params['case_id'])
    if @case.nil?
      render :json => {:success => false, :error => 'The supplied case does not exist', :error_code => 1}, :status => :bad_request
    end
    authorize! :read, @case.session

    answer = FormAnswer.new

    answer.form_id = params['form_id']
    answer.user_id = current_user.id

    answer.case_id = @case.id
    answer.session_id = @case.session.id
        
    answer.answers = params['answers']
    answer.answers_signature = params['answers_signature']

    answer.annotated_images = params['annotated_images']
    answer.annotated_images_signature = params['annotated_images_signature']
    
    answer.is_test_data = (can? :validate, @case.session)

    answer.submitted_at = Time.now

    answer.save

    render :json => {:success => true}
  end
end
