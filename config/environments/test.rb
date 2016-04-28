StudyServer::Application.configure do
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

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_files = true
  config.static_cache_control = "public, max-age=3600"

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

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
  config.image_export_root = config.data_directory + '/images_export'

  config.dcm2xml = '/usr/bin/dcm2xml'
  config.dcmconv = '/usr/bin/dcmconv'
  config.dcmj2pnm = '/usr/bin/dcmj2pnm'

  config.wado_dicom_prefix = '999.999.999.'

  config.domino_integration_username = 'erica'
  config.domino_integration_password = 'test'
  config.domino_integration_readonly = false

  config.erica_remote_signing_key = 'config/erica_remote_signing_development.pem'
  config.erica_remote_verification_key = 'config/erica_remote_verification_development.pem'

  config.airbrake_api_key = '75336396cd50acb145d5a78eaca49a57'
end
