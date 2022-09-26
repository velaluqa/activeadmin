step 'a study :string' do |name|
  @study = create(:study, name: name)
end

step 'a study :string with:' do |name, table|
  options = { name: name }
  tag_list = nil

  table.to_a.each do |attribute, value|
    if attribute == "tags"
      tag_list = value
    else
      options[attribute.to_sym] = value
    end
  end

  study = build(:study, options)
  study.tag_list = tag_list if tag_list
  study.save
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

step 'study :string has configuration' do |name, config_yaml|
  study = Study.where(name: name).first
  study.update_configuration!(config_yaml)
end

step 'study :study_instance is locked' do |study|
  study.lock_configuration!
end
