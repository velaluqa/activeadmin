class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  def create
    answer = FormAnswer.new

    answer.form_id = params['form_id']
    answer.user_id = current_user.id

    the_case = Case.find(params['case_id'])
    unless(the_case.nil?)
      answer.case_id = the_case.id
      answer.session_id = the_case.session.id
    end
        
    answer.answers = params['answers']
    answer.answers_signature = params['answers_signature']

    answer.annotated_images = params['annotated_images']
    answer.annotated_images_signature = params['annotated_images_signature']

    answer.submitted_at = Time.now

    answer.save

    render :json => {:success => true}
  end
end
