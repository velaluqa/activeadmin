step 'a patient :string' do |subject_id|
  create(:patient, subject_id: subject_id)
end

step 'a patient :string for :center_instance' do |subject_id, center|
  @patient = create(:patient, subject_id: subject_id, center: center)
end

step 'a patient :string with:' do |subject_id, table|
  options = { subject_id: subject_id }
  tag_list = nil

  table.to_a.each do |attribute, value|
    if attribute == "tags"
      tag_list = value
    else
      options[attribute.to_sym] = value
    end
    options[:center] = Center.find_by(name: value) if attribute == 'center'
  end

  patient = create(:patient, options)
  patient.tag_list = tag_list if tag_list
  patient.save
end

step 'a patient with:' do |table|
  options = {}
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:center] = Center.find_by(name: value) if attribute == 'center'
  end
  create(:patient, options)
end
