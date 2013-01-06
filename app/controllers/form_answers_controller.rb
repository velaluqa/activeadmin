class FormAnswersController < ApplicationController
  before_filter :authenticate_user!

  def create
    answer = FormAnswer.new

    answer.form_id = params['form_id']
    answer.user_id = current_user.id

    view = View.find(params['view_id'])
    unless(view.nil?)
      answer.session_id = view.session.id
      answer.patient_id = view.patient.id
      answer.images = view.images
      # TODO: maybe just store the view?
    end
    
    answer.signature = params['signature']
    answer.answers = params['answers']
    answer.submitted_at = Time.now

    answer.save

    render :json => {:success => true}
  end
end
