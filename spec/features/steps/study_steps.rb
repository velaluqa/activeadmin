step 'a study :string' do |name|
  @study = create(:study, name: name)
end

step 'a study :string with:' do |name, table|
  options = { name: name }
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
  end
  create(:study, options)
end
