step 'I select :string from :string' do |value, field|
  find(:select, field).find(:option, text: /#{value}/).select_option
end

step 'I fill in :string for :string' do |value, field|
  fill_in(field, with: value)
end

step 'I click the :string button' do |locator|
  click_button(locator)
end

step 'I check :string' do |label|
  check(label)
end

step 'I uncheck :string' do |label|
  uncheck(label)
end
