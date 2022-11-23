step "form definition :string with:" do |name, attributes|
  options = {
    name: name,
    configuration: "test_form.json"
  }.merge(attributes.rows_hash.symbolize_keys)

  FactoryBot.create(
    :form_definition,
    options
  )
end

step "form definition :string" do |name|
  FactoryBot.create(
    :form_definition,
    name: name,
    configuration: "test_form.json"
  )
end

step "form session :string" do |name|
  FactoryBot.create(:form_session, name: name)
end

step ":string form data with:" do |form_definition_name, attributes|
  form_definition = FormDefinition.where(name: form_definition_name).first

  options = {
    form_definition: form_definition,
    configuration: form_definition.current_configuration,
    public_key: nil
  }

  attributes.to_a.each do |attribute, value|
    next if attribute == "resource"

    options[attribute.to_sym] =
      case attribute
      when "form_session" then FormSession.where(name: value).first
      else value
      end
  end

  form_answer = FactoryBot.build(:form_answer, options)

  attributes.to_a.each do |attribute, value|
    next unless attribute == "resource"

    type, identifier = value.split(" ")
    resource = TurnipHelper.find_record(type, identifier)

    form_answer.form_answer_resources.build(
      resource: resource
    )
  end

  form_answer.save!
end

step 'a form answer for :string signed by user :string with data:' do |form_definition_name, signee_username, answers_table|
  # find form definition
  form_definition = FormDefinition.where(name: form_definition_name).first

  # find user
  user = User.where(username: signee_username).first

  # create form data
  options = {
    form_definition: form_definition,
    configuration: form_definition.current_configuration,
    public_key: nil
  }
  form_answer = FactoryBot.create(:form_answer, options)

  # sign form data accordingly
  answers = answers_table.to_h
  signing_password = "password"
  answers_signature = nil
  annotated_images_signature = nil

  begin
    answers_signature =
      user.sign64(
        answers.to_h.to_canonical_json,
        signing_password
      )
    annotated_images_signature =
      user.sign64(
        {}.to_json,
        signing_password
      )
  rescue OpenSSL::PKey::RSAError => e
    fail "Cannot sign form answers: #{e}"
  end

  form_answer.user = user
  form_answer.public_key = user.active_public_key
  form_answer.answers = answers
  form_answer.answers_signature = answers_signature
  form_answer.annotated_images = {}
  form_answer.annotated_images_signature = annotated_images_signature
  form_answer.submitted_at = DateTime.now
  form_answer.save!
end

step 'a form answer for :string with data:' do |form_definition_name, answers_table|
  # find form definition
  form_definition = FormDefinition.where(name: form_definition_name).first

  # create form data
  options = {
    form_definition: form_definition,
    configuration: form_definition.current_configuration,
    public_key: nil,
    answers: answers_table.to_h
  }
  FactoryBot.create(:form_answer, options)
end
