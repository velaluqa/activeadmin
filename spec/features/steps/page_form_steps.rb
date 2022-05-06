step 'I select :string from :string' do |value, field|
  find(:select, field).find(:option, text: /#{value}/).select_option
end

step 'I fill in :string with :string' do |field, value|
  field = find_field(field)
  if field[:class].include?("select2-hidden-accessible")
    label = find("label", text: "Resource")
    within("[id=#{label[:for]}] + span") do
      find("input").set(value)
    end
  else
    field.set(value)
  end
  validation_report_screenshot
end

step 'I click the :string button' do |locator|
  click_button(locator)
end

step 'I click button :string' do |locator|
  click_button(locator)
end

step 'I check :string' do |label|
  check(label)
  validation_report_screenshot
end

step 'I uncheck :string' do |label|
  uncheck(label)
  validation_report_screenshot
end

step 'I provide string for file field :string' do |locator, file_contents|
  file = Tempfile.new('upload_file')
  file.write(file_contents)
  file.close
  attach_file(locator, file.path)
end

step 'I click select option :string' do |locator|
  find(:xpath, ".//li[./@role = 'treeitem']", text: locator).click
end

step "I search :string for :string and select :string" do |search, field_name, select_option|
  step "I fill in \"#{field_name}\" with \"#{search}\""
  step "I see \"#{select_option}\""
  step "I click select option \"#{select_option}\""
end
