class V1::DashboardController < ApplicationController
  layout "external_form"

  before_action :authenticate_user!

  # TODO: Extract finders either into GraphQL API layer or into a
  # trailblazer find operation.
  def index
    form_answers = FormAnswer.without_session.answerable_by(current_user)
    form_answers.map(&:unblock_expired!)
    form_sessions = FormSession.startable_by(current_user)

    render_react(
      "user_dashboard",
      current_user: current_user.attributes.slice("id", "username", "name"),
      form_answers: form_answers.includes(:form_definition, form_answer_resources: :resource).map do |answer|
        answer.attributes
          .merge(
            "form_definition" => answer.form_definition.attributes,
            "form_answer_resources" => answer.form_answer_resources.map do |fa_resource|
              fa_resource.attributes
                .merge("resource" => fa_resource.resource.attributes)
            end
          )
      end,
      form_sessions: form_sessions.map do |session|
        session
          .attributes
          .merge(
            "answers" => session
                           .form_answers
                           .order(sequence_number: :asc)
                           .map(&:attributes))
      end
    )
  end
end
