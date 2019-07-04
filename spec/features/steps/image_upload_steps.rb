step 'I select a DICOM folder for :string' do |field_name|
  # Selenium cannot handle a directory, this option is non-standard,
  # though.
  field_id = find_field(field_name, visible: :all)[:id]
  page.execute_script("document.getElementById('#{field_id}').webkitdirectory = false")
  attach_file(
    field_name,
    Dir[Rails.root.join('spec/files/dicom_upload_test/*')],
    visible: :all
  )
  validation_report_screenshot
end

step 'I select :string for upload' do |series|
  page.all('tr').each do |tr|
    tr.check if tr.text.include?(series)
  end
  validation_report_screenshot
end

step 'I select visit :string for :string' do |visit_number, series|
  page.all('tr').each do |tr|
    if tr.text.include?(series)
      tr.find('td.visit .select2').click
      page.find('li.select2-results__option', text: /#{visit_number}/).click
    end
  end
  validation_report_screenshot
end

step 'I select required series :string for :string' do |visit_number, series|
  page.all('tr').each do |tr|
    if tr.text.include?(series)
      tr.find('td.required-series .select2').click
      page.find('li.select2-results__option', text: /#{visit_number}/).click
    end
  end
  validation_report_screenshot
end
