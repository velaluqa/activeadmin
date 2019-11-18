Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Disables the Asset cache
  config.assets.cache_store = :null_store

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # When running Rails in Docker the better_error pages are not shown,
  # since the requests are not local. So we have to define trusted ips.
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']
  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.raise_delivery_errors = true

  # Default URL for Devise.
  routes.default_url_options[:host] = 'localhost:3000'
  config.action_mailer.default_options = {
    from: 'noreply@pharmtrace.com'
  }
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # custom app config
  config.data_directory = 'data'

  config.form_configs_subdirectory = 'forms'
  config.session_configs_subdirectory = 'sessions'
  config.study_configs_subdirectory = 'studies'

  config.form_configs_directory = config.data_directory + '/' + config.form_configs_subdirectory
  config.session_configs_directory = config.data_directory + '/' + config.session_configs_subdirectory
  config.study_configs_directory = config.data_directory + '/' + config.study_configs_subdirectory

  config.max_allowed_password_age = 1.month

  config.image_storage_root = config.data_directory + '/images'
  config.image_export_root = config.data_directory + '/images_export'

  config.dcm2xml = '/usr/bin/dcm2xml'
  config.dcmconv = '/usr/bin/dcmconv'
  config.dcmj2pnm = '/usr/bin/dcmj2pnm'
  config.dcmdjpeg = '/usr/bin/dcmdjpeg'

  config.wado_dicom_prefix = '999.999.999.'

  config.domino_integration_username =
    ENV['ERICA_DOMINO_USERNAME'] || 'erica'
  config.domino_integration_password =
    ENV['ERICA_DOMINO_PASSWORD'] || 'test'
  config.domino_integration_readonly =
    ENV['ERICA_DOMINO_READONLY'] == 'true'

  config.erica_remote_signing_key = 'config/erica_remote_signing_development.pem'
  config.erica_remote_verification_key = 'config/erica_remote_verification_development.pem'

  config.airbrake_api_key = '75336396cd50acb145d5a78eaca49a57'

  config.maximum_email_throttling_delay = 30 * 24 * 60 * 60 # monthly

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
