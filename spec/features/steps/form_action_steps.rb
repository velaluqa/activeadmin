step 'I select :string from :string' do |value, field|
  select(value, from: field)
end

step 'I fill in :string for :string' do |value, field|
  fill_in(field, with: value)
end

step 'I click the :string button' do |locator|
  click_button(locator)
end
