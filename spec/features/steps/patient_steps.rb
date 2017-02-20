step 'a patient :string' do |subject_id|
  create(:patient, subject_id: subject_id)
end


step 'a patient :string for :center_instance' do |subject_id, center|
  @patient = create(:patient, subject_id: subject_id, center: center)
end

step 'a patient :string with:' do  |subject_id, table|
  options = { subject_id: subject_id }
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:center] = Center.find_by(name: value) if attribute == 'center'
  end
  create(:patient, options)
end

step 'a patient with:' do |table|
  options = {}
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:center] = Center.find_by(name: value) if attribute == 'center'
  end
  create(:patient, options)
end
