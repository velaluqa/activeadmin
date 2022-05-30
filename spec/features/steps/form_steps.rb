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
    options[attribute.to_sym] =
      case attribute
      when "form_session" then FormSession.where(name: value).first
      else value
      end
  end

  FactoryBot.create(:form_answer, options)
end
