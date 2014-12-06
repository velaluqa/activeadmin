namespace = Rails.application.config.is_erica_remote ? 'erica_remote_' : 'erica_v2_'
namespace += Rails.env

Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://127.0.0.1:6379/0', :namespace => namespace }

  config.server_middleware do |chain|
    chain.add Kiqstand::Middleware
  end
end

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://127.0.0.1:6379/0', :namespace => namespace }
end
