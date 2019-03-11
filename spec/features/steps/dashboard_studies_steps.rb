step 'I see the link to select a study' do
  expect(page).to have_link('Select')
  validation_report_screenshot
end

step 'I see the link to initiate image upload' do
  expect(page).to have_link('Upload')
  validation_report_screenshot
end
