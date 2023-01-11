Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'mailcatcher-test',
    port: 1025
  }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  routes.default_url_options[:host] = 'localhost:3000'
  config.action_mailer.default_options = {
    from: 'noreply@pharmtrace.com'
  }

  # custom app config
  config.data_directory = 'spec/data'

  config.form_configs_subdirectory = 'forms'
  config.session_configs_subdirectory = 'sessions'
  config.study_configs_subdirectory = 'studies'

  config.form_configs_directory = config.data_directory + '/' + config.form_configs_subdirectory
  config.session_configs_directory = config.data_directory + '/' + config.session_configs_subdirectory
  config.study_configs_directory = config.data_directory + '/' + config.study_configs_subdirectory

  config.max_allowed_password_age = 1.month

  config.image_storage_root = config.data_directory + '/images'
  config.form_pdf_root = config.data_directory + '/form_pdfs'
  config.image_export_root = config.data_directory + '/images_export'
  config.backup_root = config.data_directory + '/backup'
  config.cache_root = config.data_directory + '/cache'

  config.dcm2xml = '/usr/bin/dcm2xml'
  config.dcm2json = '/usr/bin/dcm2json'
  config.dcmconv = '/usr/bin/dcmconv'
  config.dcmj2pnm = '/usr/bin/dcmj2pnm'

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
end
