if Rails.env.production?
  require 'airbrake'

  Airbrake.configure do |config|
    config.api_key = {
      project: 'pharmtrace-erica-store',
      api_key: 'd96a988c672384ad4924c37ca1f00d59f0e9a953',
      tracker: 'Bug',
      category: 'Development',
      priority: 2,
      assignee: 'aandersen@velalu.qa'
    }.to_json
    config.host = 'projects.velalu.qa'
    config.port = 443
    config.secure = true
  end
end
