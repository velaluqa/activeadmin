step 'a patient exists' do
  create(:patient)
end

step 'a patient exists:' do  |table|
  options = {}
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
  end
  create(:patient, options)
end
