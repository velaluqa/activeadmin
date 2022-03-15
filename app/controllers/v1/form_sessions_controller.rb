require "canonical_json"

class V1::FormSessionsController < V1::ApiController
  layout "external_form"

  before_action :authenticate_user!

  def show
    # display form if editable otherwise only values
    # authorize
    form_session = FormSession.find(params[:id])

    respond_to do |format|
      format.html do
        render_react(
          "form_sessions_show",
          current_user: current_user.attributes.pick("id", "name", "username"),
          form_session: form_session.attributes,
          form_answers: load_form_answers(form_session)
        )
      end
    end
  end

  private

  def load_form_answers(session)
    session
      .form_answers
      .order(sequence_number: :asc)
      .includes(:form_definition, form_answer_resources: :resource)
      .map(&method(:load_form_answer))
  end

  def load_form_answer(answer)
    answer
      .attributes
      .merge(
        "status" => answer.status,
        "form_definition" => answer.form_definition.attributes,
        "form_layout" => answer.layout,
        "form_answer_resources" => answer.form_answer_resources.map(&method(:load_form_answer_resource))
      )
  end

  def load_form_answer_resource(resource)
    resource
      .attributes
      .merge("resource" => resource.resource.attributes)
  end
end
