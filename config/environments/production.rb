StudyServer::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( forms_bootstrap_and_overrides.css image_hierarchy.js tqc_validation.js mqc_validation.js image_series_rearrange.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

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

  config.domino_integration_username = 'erica'
  config.domino_integration_password = 'test'
  config.domino_integration_readonly = false

  config.airbrake_api_key = '21996bca9601d39ad1aa911e03922000'
end
