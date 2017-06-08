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

step 'visit :visit_instance has required series :string assigned to :image_series_instance' do |visit, required_series, image_series|
  visit.change_required_series_assignment(required_series => image_series.id.to_s)
end

step 'visit :visit_instance required series :string has tQC with:' do |visit, required_series, tqc|
  comment = tqc.to_h['comment']
  visit.set_tqc_result(required_series, {}, @user, comment)
end
