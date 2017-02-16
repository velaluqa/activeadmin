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

step 'a study :string with configuration' do |name, config_yaml|
  study = create(:study, name: name)
  tempfile = Tempfile.new('test.yml')
  tempfile.write(config_yaml)
  tempfile.close
  repo = GitConfigRepository.new
  repo.update_config_file(study.relative_config_file_path, tempfile, nil, "New configuration file for study #{study.id}")
  tempfile.unlink
end
