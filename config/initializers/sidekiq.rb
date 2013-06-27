Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://127.0.0.1:6379/0', :namespace => 'erica_v2_'+Rails.env }
end

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://127.0.0.1:6379/0', :namespace => 'erica_v2_'+Rails.env }
end
