namespace = Rails.application.config.is_erica_remote ? 'erica_remote_' : 'erica_v2_'
namespace += Rails.env

require 'sidekiq/scheduler'

Sidekiq.configure_server do |config|
  config.redis = { :url => "redis://#{ENV['REDIS_URL'] || 'redis'}:6379/0", :namespace => namespace }

  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path("../../../config/scheduler.yml", __FILE__))
    Sidekiq::Scheduler.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { :url => "redis://#{ENV['REDIS_URL'] || 'redis'}:6379/0", :namespace => namespace }
end
