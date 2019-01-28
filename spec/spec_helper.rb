if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.command_name 'RSpec'
end

# Turnip is a Gherkin language and runner implementation with better
# formats for step definitions.
require 'turnip'
require 'turnip/capybara'
Dir.glob('spec/features/steps/**/*_steps.rb') { |f| load f, true }
load 'spec/features/steps/placeholders.rb', true
require 'capybara/rails'

require 'capybara-screenshot/rspec'
# Add <base> to saved HTML pages so that the browser can load
# respective assets when opening failing pages.
Capybara.asset_host = 'http://localhost:3000'

# Poltergeist is a headless webkit implementation and can be plugged
# into capybara.
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Capybara.default_driver = :poltergeist
Capybara.server = :puma, { Silent: true }


# Capybara starts the webserver in another thread. Running feature
# specs/steps with AJAX requests may result in race conditions.
# The gem `transaction_capybara` configures a shared database
# connection and means to wait for pending ajax requests.
require 'transactional_capybara/rspec'

require 'rack/test'

require 'yarjuf'

require 'webmock/rspec'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

require 'with_model'
require 'database_cleaner'

# Drops are encapsulations for liquid templates which are created in a
# potentially hostile environment (e.g. by the end-user).
require 'liquid4-rails/matchers'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec::Sidekiq.configure do |config|
  # Clears all job queues before each example
  config.clear_all_enqueued_jobs = true

  # Whether to use terminal colours when outputting messages
  config.enable_terminal_colours = true

  # Warn when jobs are not enqueued to Redis but to a job array
  config.warn_when_jobs_not_processed_by_sidekiq = true
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
  config.extend ControllerMacros, type: :controller
  config.extend WithModel

  def clear_data
    FileUtils.rm_rf("#{Dir.tmpdir}/erica")
    FileUtils.mkdir_p("#{Dir.tmpdir}/erica")
    FileUtils.rm_rf('spec/data')
    FileUtils.mkdir_p('spec/data/images')
    FileUtils.mkdir_p('spec/data/studies')
    FileUtils.mkdir_p('spec/data/forms')
    FileUtils.mkdir_p('spec/data/sessions')
  end

  config.before(:suite) do
    FactoryGirl.reload
    FactoryGirl.lint
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    clear_data
  end

  config.around(:each, transactional_spec: true) do |example|
    DatabaseCleaner.strategy = :deletion
    example.run
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each, paper_trail: false) do |example|
    PaperTrail.enabled = false
    example.run
    PaperTrail.enabled = true
  end

  config.around(:each) do |example|
    clear_data
    DatabaseCleaner.cleaning do
      example.run
    end
    ::PaperTrail.whodunnit = nil
  end

  # Disable webmock in feature test.
  config.before(type: :feature) do
    WebMock.allow_net_connect!
  end
  config.after(type: :feature) do
    WebMock.disable_net_connect!
  end

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explictly tag your specs with their type, e.g.:
  #
  #     describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/v/3-0/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Ensure that spec tmp directory exists.
  FileUtils.mkdir_p('spec/tmp')
end
