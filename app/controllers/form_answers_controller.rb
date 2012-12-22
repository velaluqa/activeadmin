class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  def create
    answer = FormAnswer.new

    answer.form_id = params['form_id']
    answer.user_id = current_user.id
    answer.session_id = 42 #HC
    answer.patient_id = 23 #HC
    answer.images = "baseline" #HC

    answer.signature = params['signature']
    answer.answers = params['answers']
    answer.submitted_at = Time.now

    answer.save

    render :json => {:success => true}
  end
end
