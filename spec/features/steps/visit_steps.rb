step 'a visit :string' do |visit_number|
  create(:visit, visit_number: visit_number)
end

step 'a visit :string for :patient_instance' do |visit_number, patient|
  @visit = create(:visit, visit_number: visit_number, patient: patient)
end

step 'a visit :string with:' do |visit_number, table|
  options = { visit_number: visit_number }
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:patient] = Patient.find_by(subject_id: value) if attribute == 'patient'
  end
  create(:visit, options)
end

step 'a visit with:' do |table|
  options = {}
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:patient] = Patient.find_by(subject_id: value) if attribute == 'patient'
  end
  create(:visit, options)
end
