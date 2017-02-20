step 'I see the link to select a study' do
  expect(page).to have_content('Select')
end

step 'I see the link to initiate image upload' do
  expect(page).to have_content('Upload')
end
