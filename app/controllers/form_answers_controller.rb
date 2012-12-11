class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  def create
    answer = FormAnswer.new
    answer.answers = params[:form_answer]
    answer.reader = 23
    answer.read = 42
    answer.form_id = 1
    answer.form_timestamp = Time.now
    answer.submitted_at = Time.now

    answer.save

    render :json => {:success => true}
  end
end
