require_relative 'boot'

# Require standard library extensions before anything rails specific,
# so that ActiveSupport has the last word in terms of method
# definitions.
require 'facets/enumerable/mash'

# Require Rails.
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'pp'

module StudyServer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.template_engine :haml
    end

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{config.root}/app/workers #{config.root}/app/models/concerns #{config.root}/app/drops]


    config.active_job.queue_adapter = :sidekiq

    Dir[Rails.root.join('lib', 'middleware', '*.{rb}')].each {|file| require file}

    config.middleware.use Middleware::Maintenance

    # Set Time.zone default to the specified zone and make Active
    # Record auto-convert to this zone. Run "rake -D time" for a list
    # of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end
