git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

source 'https://rubygems.org'

gem 'rails', '~> 5.2.3'
gem 'bootsnap'

# With Rails 4.0 some gems were extracted into separate gems, which
# need to be installed separately. Some gems are deprecated and we
# should make sure to remove the dependency within our app.
# TODO: Remove protected attributes in favor of strong parameters
gem 'protected_attributes_continued'

gem 'pg'
gem 'sqlite3'

gem 'json'

# HAML templating engine
# needs to be added explicitely, otherwise it might not register itself as a templating engine in Rails
gem 'haml'

# Liquid Templating Engine for User generated Templates
# TODO: Liquid is waiting for release since March. Use the released
# rubygem when it's available.
gem 'liquid', github: 'velaluqa/liquid', branch: 'master'
gem 'liquid4-rails'

# Gems used for assets
gem 'coffee-rails'
gem 'sass-rails'

gem 'haml-rails'
gem 'less-rails'

gem 'bootstrap-datepicker-rails'
gem 'bootstrap-sass'

gem 'font-awesome-sass'

gem 'uglifier'

# we need these even in production, for server-side judgement functions
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'
gem 'libv8'
gem 'therubyracer', platforms: :ruby

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

# authentication/authorization
gem 'cancancan'
gem 'devise'
gem 'devise-token_authenticatable'

# audit trail
gem 'paper_trail'

# ActiveAdmin
gem 'activeadmin'

# CodeRay for rendering yaml/json data
gem 'coderay'

# Ultraviolet allows to use TextMate syntax files, thus enabling easy
# highlighting of liquid templates.
gem 'textpow', github: 'velaluqa/textpow', branch: 'master'
gem 'ultraviolet'

# Rugged for Git-based config versioning
gem 'rugged'

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
gem 'sidekiq-unique-jobs'

# Sideiq-scheduler is used for recurring jobs (i.e. checking for and
# sending notifications via e-Mail).
gem 'sidekiq-scheduler'

# Ruby DICOM lib
gem 'dicom'

# Zip file creation for image download in ERICA Remote
gem 'rubyzip'

# Resource tagging in ERICA Remote
gem 'acts-as-taggable-on', '~> 6.0.0'

gem 'ruby-progressbar'

gem 'andand'

# Facets provides many helpers that are missing from the ruby standard library.
gem 'facets', require: false

# For the Sidekiq monitoring interface
gem 'sinatra', require: nil
gem 'slim'

# FactoryGirl is used in production to create seed data.
gem 'factory_bot_rails'
gem 'faker'

# Awesome Print for pretty printing of Ruby Objects
gem 'awesome_print'

# Use HAML and CoffeeScript for Backbone.JS SPAs
gem 'haml_coffee_assets'
gem 'sprockets-rails'

# Validate JSONB columns via JSONschema
gem 'activerecord_json_validator'

# Enhanced `Array#dig` and `Hash#dig` for digging nested array/hash structures.
gem 'ruby_dig2'

# Help pages use markdown to generate markup.
gem 'redcarpet'

# Used for inlining mail assets into sent mails.
gem 'nokogiri'
gem 'premailer-rails'

gem 'trailblazer-rails'
gem 'dry-types'

group :development do
  # Hint opimization opportunities while developing.
  gem 'bullet'
  # Chrome extension to get meta info for the current request.
  gem 'meta_request'
  # Generate UML diagrams for the database.
  gem 'railroady'
  gem 'rails-erd'
  # Hints missing indexes.
  gem 'lol_dba'

  # Gems for prettier errors in development
  gem 'better_errors'
  gem 'binding_of_caller'

  # Catching mails and serving them locally via a web interface.
  gem 'letter_opener_web'
end

group :test do
  gem 'rspec-sidekiq'
  gem 'webmock'
end

group :development, :test do
  # Ruby console tool and additional extensions
  gem 'hirb'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'pry-git'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-stack_explorer'

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
  gem 'simplecov-rcov', require: false
  gem 'yard', require: false
  gem 'yard-activerecord', github: 'velaluqa/yard-activerecord', require: false
  gem 'yard-activesupport-concern', require: false

  gem 'capybara'
  gem 'puma' # for capybara

  # Lock capybara-screenshot because it's being monkey-patched for the
  # validation report
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'selenium-webdriver'
  gem 'transactional_capybara'
  gem 'yarjuf'

  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'rspec'
  gem 'rspec-mocks'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'with_model'
  # Spec delegation via ActiveSupport's #delegate method.
  gem 'delegate_matcher'
  gem 'timecop'

  gem 'gherkin'
  # Installs 2.0.1 with non-working gherkin 6 without a version
  # constraint
  #
  # Lock turnip because it's being monkey-patched for the validation
  # report
  gem 'turnip', '3.1.0'

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
