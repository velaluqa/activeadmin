step 'a center :string' do |name|
  @center = create(:center, name: name)
end

step 'a center :string for :study_instance' do |name, study|
  @center = create(:center, name: name, study: study)
end

step 'a center :string with:' do |name, table|
  options = { name: name }
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:study] = Study.find_by(name: value) if attribute == 'study'
  end
  create(:center, options)
end
