step 'I select a DICOM folder for :string' do |field_name|
  attach_file(field_name, Rails.root.join('spec/files/dicom_upload_test/IM-0001-0001.dcm').to_s)
end

step 'I select :string for upload' do |series|
  page.all('tr').each do |tr|
    if tr.text.include?(series)
      tr.find('td.upload-flag input').set('true')
    end
  end
end

step 'I select visit :string for :string' do |visit_number, series|
  page.all('tr').each do |tr|
    if tr.text.include?(series)
      tr.find('td.visit .select2').click
      page.find('li.select2-results__option', text: /#{visit_number}/).click
    end
  end
end

step 'I select required series :string for :string' do |visit_number, series|
  page.all('tr').each do |tr|
    if tr.text.include?(series)
      tr.find('td.required-series .select2').click
      page.find('li.select2-results__option', text: /#{visit_number}/).click
    end
  end
end
