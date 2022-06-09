step 'I fill in the comments textarea with :string' do |value|
  find_field("active_admin_comment_body").set(value)
end

step 'I select :string from :string' do |value, field|
  find(:select, field).find(:option, text: /#{value}/).select_option
end

step 'I fill in :string with :string' do |field_name, value|
  label = find(:label, text: /^#{field_name}\*?$/)
  label_for = label[:for]
  field = find_field(label_for)
  if field[:class].include?("select2-hidden-accessible")
    within("[id=#{field[:id]}] + span") do
      find("input").set(value)
    end
  else
    field.set(value)

    # This expectation is necessary to make selenium wait until the
    # text is completely entered. Otherwise the next step might begin
    # too early causing only a part of the `value` to be sent with a
    # form upon submit.
    expect(page).to have_field(field_name, with: value)
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
  # Selenium does not support directory file fields.
  field_id = find_field(field, visible: :all)[:id]
  page.execute_script("document.getElementById('#{field_id}').webkitdirectory = false")
  page.attach_file("/app/spec/files/#{filename}") do
    find("label", text: field).click
  end
end

step 'I provide directory :string for :string' do |filename, field|
  # Selenium cannot handle a directory, this option is non-standard,
  # though.
  field_id = find_field(field, visible: :all)[:id]
  page.execute_script("document.getElementById('#{field_id}').webkitdirectory = false")

  attach_file(
    field,
    Dir[Rails.root.join("spec/files/#{filename}/*")],
    visible: :all
  )

  validation_report_screenshot
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

step 'I see field :string with value :string' do |locator, value|
  label_element = find(:label, text: /^#{locator}\*?$/)
  label_for = label_element[:for]

  expect(page).to have_field(label_for, with: value)
end

step "I fill in number field :string with :count" do |field_name, count|
  fill_in(field_name, with: count)
end