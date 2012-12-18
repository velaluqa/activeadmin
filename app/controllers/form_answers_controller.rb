class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  def create
    answer = FormAnswer.new
    answer.signature = params[:form_answer].delete('signature')
    answer.form_id = params[:form_answer].delete('form_id')
    answer.answers = params[:form_answer]
    answer.reader = current_user.id
    answer.read = 42
    answer.submitted_at = Time.now

    answer.save

    render :json => {:success => true}
  end
end
