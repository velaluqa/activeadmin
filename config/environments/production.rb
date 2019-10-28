Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "study_server_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

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

  config.airbrake_api_key = '21996bca9601d39ad1aa911e03922000'

  config.maximum_email_throttling_delay = 30 * 24 * 60 * 60 # monthly

  config.action_mailer.default_options = {
    from: (ENV['SMTP_SENDER'] || 'noreply@pharmtrace.com')
  }

  config.action_mailer.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    port: (ENV['SMTP_PORT'] || '587').to_i,
    address: ENV['SMTP_SERVER'],
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: (ENV['SMTP_AUTH'] || 'plain').to_sym,
    enable_starttls_auto: (ENV['SMTP_STARTTLS_AUTO'] == 'true')
  }
  routes.default_url_options[:host] = ENV['ERICA_HOST']

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
