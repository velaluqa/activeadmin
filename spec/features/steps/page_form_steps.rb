step 'I select :string from :string' do |value, field|
  find(:select, field).find(:option, text: /#{value}/).select_option
end

step 'I fill in :string with :string' do |field, value|
  fill_in(field, with: value)
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
