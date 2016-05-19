step 'I should see :text in the studies list' do |text|
  expect(page).to have_content(text)
end

step 'there is a study called :text' do |name|
  @study = create(:study, name: name)
end

step 'I see study :text in the studies list' do |name|
  expect(page).to have_content(name)
end

step 'I see the link to select a study' do
  expect(page).to have_content('Select')
end

step 'I see the link to initiate image upload' do
  expect(page).to have_content('Upload')
end
