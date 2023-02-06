git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

source 'https://rubygems.org'

ruby "3.2.0"

gem 'rails', '~> 7.0.0' # >= 7.0.0, < 7.1.0
gem 'bootsnap'

# XML serialization was removed from rails 5 and extracted into its
# own gem.
gem "activemodel-serializers-xml"

gem 'draper'

gem 'pg'
gem 'sqlite3'

gem 'json'

# HAML templating engine
# needs to be added explicitely, otherwise it might not register itself as a templating engine in Rails
gem 'haml'

# Liquid Templating Engine for User generated Templates
gem 'liquid', '~> 5.0.0'
gem 'liquid-rails', github: 'velaluqa/liquid-rails', branch: 'master'

# Gems used for assets
gem 'coffee-rails'
gem 'sass-rails'

gem 'haml-rails'

gem 'bootstrap-datepicker-rails'
gem 'bootstrap-sass'

gem 'font-awesome-sass'

gem 'uglifier'

# we need these even in production, for server-side judgement functions
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'

gem 'libv8-node', '~> 16.10.0.0'
gem 'mini_racer'

gem 'jquery-rails'
gem 'jquery-ui-rails'

# To use ActiveModel has_secure_password
gem 'bcrypt'

# To use Jbuilder templates for JSON
gem 'jbuilder'

# Use unicorn as the app server
gem 'kgio'
gem 'raindrops'
gem 'unicorn'

# used for user impersonation
gem 'pretender'

# authentication/authorization
gem 'cancancan'
gem 'devise'
gem 'devise-token_authenticatable'

# audit trail
gem 'paper_trail'

# ActiveAdmin
gem 'activeadmin', '~> 2.12.0'

gem 'kaminari', '~> 1.2.0'

# CodeRay for rendering yaml/json data
gem 'coderay'

# Ultraviolet allows to use TextMate syntax files, thus enabling easy
# highlighting of liquid templates.
gem 'textpow', github: 'velaluqa/textpow', branch: 'master'
gem 'ultraviolet'

# Rugged for Git-based config versioning
gem 'rugged', '~> 1.5', '>= 1.5.1'

# Airbrake Exception notifier
gem 'airbrake'

# Kwalify schema validator
gem 'kwalify'

# diff library for config changes display
gem 'diffy'

# select2 gem for integration with asset pipeline
gem 'select2-rails'

# rest-client gem to access Domino Data Services REST API
gem 'rest-client'

# used for DICOM based checks in tQC (ability to specify simple formulas)
# the gem on rubygems.org is not up-to-date, so we use the code from github directly
gem 'dentaku'

# Sidekiq is used for asynchronous job execution, i.e. DICOM searches, exports, ...
gem 'sidekiq', '~> 5.0'
gem 'sidekiq-unique-jobs', '~> 6.0.22'

# Sideiq-scheduler is used for recurring jobs (i.e. checking for and
# sending notifications via e-Mail).
gem 'sidekiq-scheduler'

# Ruby DICOM lib
gem 'dicom'
gem 'rmagick'

# Generate PDF via chrome and puppeteer.
gem 'grover'

# Identify mime type by header bytes of file content instead of file extension.
gem 'marcel', '1.0.2'

# Zip file creation for image download in ERICA Remote
gem 'rubyzip'

# Resource tagging in ERICA Remote
gem 'acts-as-taggable-on', '~> 9.0.0'

gem 'ruby-progressbar'

gem 'andand'

# Facets provides many helpers that are missing from the ruby standard library.
gem 'facets', require: false

# FactoryBot is used in production to create seed data.
gem 'factory_bot_rails'
gem 'faker'

# Awesome Print for pretty printing of Ruby Objects
gem 'awesome_print'

# Use HAML and CoffeeScript for Backbone.JS SPAs
gem 'haml_coffee_assets', '~> 1.21.0'
gem 'sprockets-rails'
gem 'sprockets', '~> 4.2'

# Use webpacker & webpack for all modern assets
gem 'webpacker', '~> 4.x'

# Validate JSONB columns via JSONschema
gem 'activerecord_json_validator'
gem 'json-schema', '~> 2.8.0'

# Enum creation macros for migrations
gem 'activerecord-postgres_enum'

# Enhanced `Array#dig` and `Hash#dig` for digging nested array/hash structures.
gem 'ruby_dig2'

# Help pages use markdown to generate markup.
gem 'redcarpet'

# Used for inlining mail assets into sent mails.
gem 'nokogiri'
gem 'premailer-rails'

gem 'trailblazer-rails'
gem 'reform-rails'
gem 'dry-types'

group :development do
  # Hint opimization opportunities while developing.
  gem 'bullet'
  # Chrome extension to get meta info for the current request.
  gem 'meta_request', github: 'velaluqa/rails_panel', branch: 'master'
  # Generate UML diagrams for the database.
  gem 'railroady'
  gem 'rails-erd'
  # Hints missing indexes.
  gem 'lol_dba', '~> 2.4.0'

  # Gems for prettier errors in development
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test do
  gem 'test-prof', '~> 1.0'
  gem 'stackprof', require: false
  gem 'ruby-prof', require: false
  gem 'rspec-sidekiq'
  gem 'webmock'
end

group :development, :test do
  # Ruby console tool and additional extensions
  gem 'hirb'
  gem 'pry'
  gem 'pry-byebug', '~> 3.9'
  gem 'pry-doc'
  gem 'pry-git'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-stack_explorer'

  # this improves CI test suite performance
  gem 'knapsack'

  # Profiling memory usage
  gem 'memory_profiler'

  # Rubocop ensures the ruby style guide.
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter', require: false

  gem 'rails_best_practices'
  # gem 'rails_best_practices-formatter'

  # Rails Security metrics
  gem 'brakeman', require: false

  # Checks the code climate/code smells
  gem 'flay'
  gem 'flog'
  gem 'reek'
  gem 'rubycritic', require: false

  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
  gem 'simplecov-json', require: false
  gem 'yard', require: false
  gem 'yard-activerecord', github: 'velaluqa/yard-activerecord', require: false
  gem 'yard-activesupport-concern', require: false

  gem 'capybara', '~> 3.36.0'
  gem 'puma', '~> 5.0' # for capybara

  # Lock capybara-screenshot because it's being monkey-patched for the
  # validation report
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'selenium-webdriver', '~> 4.1.0'
  gem 'transactional_capybara'
  gem 'yarjuf'

  # for working with capybara and select2 JS library
  gem 'capybara-select-2'

  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'rspec', '~> 3.10'
  gem 'rspec-mocks', '~> 3.10'
  gem 'rspec-rails', '~> 5.1'
  gem 'shoulda-matchers'
  gem 'with_model', '~> 2.1.3'
  # Spec delegation via ActiveSupport's #delegate method.
  gem 'delegate_matcher'
  gem 'timecop'

  gem 'gherkin'
  # Installs 2.0.1 with non-working gherkin 6 without a version
  # constraint
  #
  # Lock turnip because it's being monkey-patched for the validation
  # report
  gem 'turnip'

  # Extension of rspec's default documentation formatter for turnip
  gem 'turnip_documentation_formatter'

  gem 'guard'
  gem 'guard-livereload'
  gem 'guard-rspec'

  gem 'redis-namespace'
  gem 'test-unit'

  # Kramdown is generated by the annotate gem and should be used by YaRD.
  gem 'kramdown'

  # Annotate models.
  # This will add model column descriptions to the top comment of your
  # models. Through migration hooks it keeps these comments up-to-date.
  gem 'annotate'

  # Bundler-audit helps finding gems that need to be patched for
  # security. Also it provides recommendations for certain
  # dependencies.
  gem 'bundler-audit'
end
