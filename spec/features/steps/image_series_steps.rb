step 'a/an image_series :string' do |name|
  create(:image_series, name: name)
end

step 'a/an image_series :string for :patient_instance' do |name, patient|
  @image_series = create(:image_series, name: name, patient: patient)
end

step 'a/an image_series :string for :patient_instance with :number images' do |name, patient, image_number|
  @image_series = create(:image_series, name: name, patient: patient)
  1.upto(image_number.to_i) do |i|
    create(:image, image_series_id: @image_series.id)
  end
end

step 'a/an image_series :string with:' do |name, table|
  image_count = 0
  options = { name: name }
  table.to_a.each do |attribute, value|
    if attribute == 'image_count'
      image_count = value.to_i
    else
      options[attribute.to_sym] = value
    end
    options[:patient] = Patient.find_by(subject_id: value) if attribute == 'patient'
    options[:visit] = Visit.find_by(visit_number: value) if attribute == 'visit'
  end
  @image_series = create(:image_series, options)
  if image_count > 0
    1.upto(image_count) do |i|
      create(:image, image_series_id: @image_series.id)
    end
  end
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
