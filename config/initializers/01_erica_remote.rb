require 'yaml'

erica_remote_config_path = Rails.root.join('config', 'erica_remote.yml')
begin
  erica_remote_config = YAML.load_file(erica_remote_config_path)
  puts "Loading ERICA remote config found at '#{erica_remote_config_path}'"
  pp erica_remote_config

  if erica_remote_config['erica_remote'].andand['enabled']
    Rails.application.config.erica_remote = erica_remote_config['erica_remote']
    Rails.application.config.is_erica_remote = true
  else
    Rails.application.config.erica_remote = nil
    Rails.application.config.is_erica_remote = false
  end
rescue Errno::ENOENT
  Rails.application.config.erica_remote = nil
  Rails.application.config.is_erica_remote = false
end

FileUtils.mkpath(ERICA.image_storage_path) if ERICA.remote?
