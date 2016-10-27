StudyServer::Application.configure do
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

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_files = true

  # Compress JavaScripts and CSS
  config.assets.compress = true
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Precompile additional assets (application.js, application.css, and
  # all non-JS/CSS are already added).
  config.assets.precompile += %w( forms_bootstrap_and_overrides.css image_hierarchy.js tqc_validation.js mqc_validation.js image_series_rearrange.js )

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

  config.wado_dicom_prefix = '999.999.999.'

  config.domino_integration_username = 'erica'
  config.domino_integration_password = 'test'
  config.domino_integration_readonly = false

  config.airbrake_api_key = '21996bca9601d39ad1aa911e03922000'

  config.maximum_email_throttling_delay = 30*24*60*60 # monthly

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
end
