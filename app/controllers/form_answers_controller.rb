require 'pp'

class FormAnswersController < ApplicationController
  def create
    # params: answers as json hash, rest from session?
    pp params[:form_answer]

    answer = FormAnswer.new
    answer.answers = params[:form_answer]
    answer.reader = 23
    answer.read = 42
    answer.form_id = 1
    answer.form_timestamp = Time.now
    answer.submitted_at = Time.now

    pp answer
    pp answer.save

    render :json => {:success => true}
  end
end
