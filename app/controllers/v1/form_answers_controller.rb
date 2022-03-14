require "canonical_json"

class V1::FormAnswersController < V1::ApiController
  layout "external_form"

  before_action :authenticate_user!

  skip_before_action :authenticate_user!, if: :authenticating_signature_param?

  def new
    # display empty form
    # authorize user
    form_definition = FormDefinition.find(params[:form_id])

    render_react(
      "form_answers_new",
      current_user: current_user.attributes.slice("id", "username", "name"),
      form_definition: form_definition.attributes,
      configuration: form_definition.configuration.attributes,
      form_layout: form_definition.layout
    )
  end

  def create
    # authorize user
    # validate parameters
    # create form answers
    configuration = ::Configuration.find(form_params[:configuration_id])
    answers = form_params[:answers]
    signing_password = form_params[:signing_password]
    answers_signature = nil
    annotated_images_signature = nil

    begin
      answers_signature =
        current_user.sign64(answers.to_h.to_canonical_json, signing_password)
      annotated_images_signature =
        current_user.sign64({}.to_json, signing_password)
    rescue OpenSSL::PKey::RSAError => e
      render(
        json: {
          status: 401,
          error: e.to_s
        },
        status: 401
      )
      return
    end

    form_answer = FormAnswer.create!(
      form_definition_id: params[:form_id],
      configuration: configuration,
      public_key: current_user.active_public_key,
      answers: answers,
      answers_signature: answers_signature,
      annotated_images: {},
      annotated_images_signature: annotated_images_signature,
      submitted_at: DateTime.now
    )

    respond_to do |format|
      format.json do
        render(
          json: {
            status: 200,
            form_answer_id: form_answer.id,
            message: "submitted_and_signed"
          },
          status: 200
        )
      end
    end
  end

  def show
    # display form if editable otherwise only values
    # authorize
    form_answer = FormAnswer.find(params[:id])

    respond_to do |format|
      format.html do
        render_react(
          "form_answers_show",
          form_answer: form_answer.attributes,
          signature_user: form_answer.public_key.user.attributes.pick("id", "name", "username"),
          form_definition: form_answer.form_definition.attributes,
          form_layout: form_answer.layout
        )
      end
      format.pdf do
        send_data(
          form_answer.pdfa,
          filename: "#{form_answer.form_definition.name}_answers_#{form_answer.public_key.user.name.gsub(" ", "_")}_#{form_answer.submitted_at.iso8601(3)}.pdf",
          disposition: 'inline'
        )
      end
    end
  end

  def edit
    # TODO: authorize
    form_answer = FormAnswer.find(params[:id])

    render_react(
      "form_answers_edit",
      form_answer: form_answer.attributes,
      current_user: current_user.attributes.pick("id", "name", "username"),
      form_definition: form_answer.form_definition.attributes,
      form_layout: form_answer.layout
    )
  end

  def update

  end

  def sign
    answers = form_params[:answers]
    signing_password = form_params[:signing_password]
    answers_signature = nil
    annotated_images_signature = nil

    begin
      answers_signature =
        current_user.sign64(answers.to_h.to_canonical_json, signing_password)
      annotated_images_signature =
        current_user.sign64({}.to_json, signing_password)
    rescue OpenSSL::PKey::RSAError => e
      render(
        json: {
          status: 401,
          error: e.to_s
        },
        status: 401
      )
      return
    end

    form_answer = FormAnswer.find(params[:id])
    form_answer.user = current_user
    form_answer.public_key = current_user.active_public_key
    form_answer.answers = answers
    form_answer.answers_signature = answers_signature
    form_answer.annotated_images = {}
    form_answer.annotated_images_signature = annotated_images_signature
    form_answer.submitted_at = DateTime.now
    form_answer.save!

    respond_to do |format|
      format.json do
        render(
          json: {
            status: 200,
            form_answer_id: form_answer.id,
            message: "submitted_and_signed"
          },
          status: 200
        )
      end
    end
  end

  private

  def form_params
    params.require(:form_answer).permit(
      :configuration_id,
      :signing_password,
      answers: {}
    )
  end

  def authenticating_signature_param?
    return false unless action_name == "show"
    return false unless params[:id]

    form_answer = FormAnswer.find(params[:id])

    params[:sigH] == Digest::SHA1.hexdigest(form_answer.answers_signature)
  end
end
