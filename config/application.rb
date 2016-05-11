require File.expand_path('../boot', __FILE__)

# Require standard library extensions before anything rails specific,
# so that ActiveSupport has the last word in terms of method
# definitions.
require 'facets/enumerable/mash'

# Require Rails.
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module StudyServer
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.template_engine :haml
    end

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/app/workers #{config.root}/app/models/concerns)

    # Activate observers that should always be running.
    config.active_record.observers = :image_storage_observer

    # Opt-in into the future default behaviour.
    config.active_record.raise_in_transactional_callbacks = true

    # Set Time.zone default to the specified zone and make Active
    # Record auto-convert to this zone. Run "rake -D time" for a list
    # of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Prior to Rails 4, we had to activate this security measure
    # manually. With Rails 4 we have:
    #
    #     ActiveSupport.escape_html_entities_in_json == true
    #
    # To change this configuration use:
    #
    #     config.active_support.escape_html_entities_in_json = false
  end
end
