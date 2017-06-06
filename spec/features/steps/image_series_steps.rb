step 'a/an image_series :string' do |name|
  create(:image_series, name: name)
end

step 'a/an image_series :string for :patient_instance' do |name, patient|
  @image_series = create(:image_series, name: name, patient: patient)
end

step 'a/an image_series :string with:' do |name, table|
  options = { name: name }
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:patient] = Patient.find_by(subject_id: value) if attribute == 'patient'
    options[:visit] = Visit.find_by(visit_number: value) if attribute == 'visit'
  end
  create(:image_series, options)
end

step 'a/an image_series with:' do |table|
  options = {}
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:patient] = Patient.find_by(subject_id: value) if attribute == 'patient'
    options[:visit] = Visit.find_by(visit_number: value) if attribute == 'visit'
  end
  create(:image_series, options)
end
