require 'yaml'

erica_remote_config_path = Rails.root + 'config/erica_remote.yml'
begin
  erica_remote_config = YAML::load_file(erica_remote_config_path)
  pp erica_remote_config

  if(erica_remote_config['erica_remote'] and erica_remote_config['erica_remote']['enabled'])
    Rails.application.config.erica_remote = erica_remote_config['erica_remote']
    Rails.application.config.is_erica_remote = true
  else
    Rails.application.config.erica_remote = nil
    Rails.application.config.is_erica_remote = false
  end
rescue Errno::ENOENT => e
  puts "No ERICA remote config file found at '#{erica_remote_config_path}', not loading ERICA remote"
  Rails.application.config.erica_remote = nil
  Rails.application.config.is_erica_remote = false
end

if(Rails.application.config.is_erica_remote)
  FileUtils.mkpath(Rails.root.join(Rails.application.config.image_storage_root))
end
