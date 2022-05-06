step 'I select :string from :string' do |value, field|
  find(:select, field).find(:option, text: /#{value}/).select_option
end

step 'I fill in :string with :string' do |field_name, value|
  field = find_field(field_name)
  if field[:class].include?("select2-hidden-accessible")
    within("[id=#{field[:id]}] + span") do
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

step 'I provide file :string for :string' do |filename, field|
  page.attach_file("/app/spec/files/#{filename}") do
    find("label", text: field).click
  end
end

step 'I click select option :string' do |locator|
  find(:xpath, ".//li[./@role = 'treeitem']", text: locator).click
end

step "I search :string for :string and select :string" do |search, field_name, select_option|
  step "I fill in \"#{field_name}\" with \"#{search}\""
  step "I see \"#{select_option}\""
  step "I click select option \"#{select_option}\""
end

step "I select :string for row :string" do |select_option, row_text|
  field = within("tr", text: /#{row_text}/) { find("select") }
  if field[:class].include?("select2-hidden-accessible")
    find("[id=#{field[:id]}] + span").click
    find(:xpath, ".//li[./@role = 'treeitem']", text: select_option).click
  else
    field.set(value)
  end
end

step "I select :string for :string" do |select_option, label|
  field = find_field(label)
  if field[:class].include?("select2-hidden-accessible")
    find("[id=#{field[:id]}] + span").click
    find(:xpath, ".//li[./@role = 'treeitem']", text: select_option).click
  else
    field.set(value)
  end
end
