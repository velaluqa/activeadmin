step 'a center :string' do |name|
  @center = create(:center, name: name)
end

step 'a center :string for :study_instance' do |name, study|
  @center = create(:center, name: name, study: study)
end

step 'a center :string with:' do |name, table|
  options = { name: name }
  tag_list = nil

  table.to_a.each do |attribute, value|
    if attribute == "tags"
      tag_list = value
    else
      options[attribute.to_sym] = value
    end
    options[:study] = Study.find_by(name: value) if attribute == 'study'
  end

  center = create(:center, options)
  center.tag_list = tag_list if tag_list
  center.save
end
