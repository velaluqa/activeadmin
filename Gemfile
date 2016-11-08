# coding: utf-8
if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'https://rubygems.org'

gem 'rails', '4.2.6'
gem 'railties', '4.2.6'

# With Rails 4.0 some gems were extracted into separate gems, which
# need to be installed separately. Some gems are deprecated and we
# should make sure to remove the dependency within our app.
# TODO: Remove deprecated Rails functionality for Rails 4.0
gem 'protected_attributes' # https://github.com/rails/protected_attributes
gem 'activeresource' # https://github.com/rails/activeresource
gem 'actionpack-action_caching' # https://github.com/rails/actionpack-action_caching
gem 'activerecord-session_store' # https://github.com/rails/activerecord-session_store

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3', '~> 1.3.11'
gem 'pg'

# MongoDB & MongoDB history for audit trail
# TODO: Remove Mongoid when all systems are migrated successfully.
gem 'mongoid', '~> 5.1.2'
gem 'mongoid-history', '~> 0.5.0'

gem 'json', '~> 1.8.3'

# HAML templating engine
# needs to be added explicitely, otherwise it might not register itself as a templating engine in Rails
gem 'haml', '~> 4.0.7'

# Liquid Templating Engine for User generated Templates
# TODO: Liquid is waiting for release since March. Use the released
# rubygem when it's available.
gem 'liquid', github: 'velaluqa/liquid', branch: 'master'
gem 'liquid4-rails', '~> 0.2.0'

# Gems used for assets
gem 'sass-rails',   '~> 5.0.4'
gem 'coffee-rails', '~> 4.1.1'

gem 'haml-rails', '~> 0.9.0'
gem 'less-rails', '~> 2.7.1'

gem 'twitter-bootstrap-rails'
gem 'bootstrap-datepicker-rails', '~> 1.6.0.1'

gem 'uglifier', '>= 1.0.3'

# we need these even in production, for server-side judgement functions
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'libv8', '~> 3.11.8'
gem 'therubyracer', :platforms => :ruby
gem 'execjs'

gem 'jquery-rails', '~> 3.1.4'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
gem 'jbuilder'

# Use unicorn as the app server
gem 'kgio', '~> 2.10.0'
gem 'raindrops', '~> 0.16.0'
gem 'unicorn', '~> 5.1.0'

# Deploy with Capistrano
# gem 'capistrano'

# authentication/authorization
gem 'devise', '~> 3.5.2'
gem 'devise-token_authenticatable', '~> 0.4.6'
gem 'cancancan', '~> 1.13.1'

# audit trail
gem 'paper_trail', '~> 4.1.0'

# ActiveAdmin
gem 'activeadmin', '1.0.0.pre2'

# CodeRay for rendering yaml/json data
gem 'coderay'

# Rugged for Git-based config versioning
gem 'rugged', '~> 0.24.0'

# Airbrake Exception notifier
gem 'airbrake', '~> 4.3'

# Kwalify schema validator
gem 'kwalify'

# diff library for config changes display
gem 'diffy'

# select2 gem for integration with asset pipeline
gem 'select2-rails', '~> 4.0.1'

# rest-client gem to access Domino Data Services REST API
gem 'rest-client'

# Used during GoodImage migration
# group :goodimage_migration do
#   gem 'data_mapper'
#   gem 'dm-mysql-adapter'
#   gem 'dm-sqlite-adapter'
# end

# used for DICOM based checks in tQC (ability to specify simple formulas)
# the gem on rubygems.org is not up-to-date, so we use the code from github directly
gem 'dentaku', '~> 2.0.7'

# Sidekiq is used for asynchronous job execution, i.e. DICOM searches, exports, ...
gem 'sidekiq'

# Sideiq-scheduler is used for recurring jobs (i.e. checking for and
# sending notifications via e-Mail).
gem 'sidekiq-scheduler', '~> 2.0'

# Ruby DICOM lib
gem 'dicom'

# Zip file creation for image download in ERICA Remote
gem 'rubyzip'

# Resource tagging in ERICA Remote
gem 'acts-as-taggable-on'

gem 'ruby-progressbar'

gem 'andand'

# Facets provides many helpers that are missing from the ruby standard library.
gem 'facets', require: false

# For the Sidekiq monitoring interface
gem 'slim', '>= 1.1.0'
gem 'sinatra', '>= 1.3.0', :require => nil

# FactoryGirl is used in production to create seed data.
gem 'faker'
gem 'factory_girl_rails', '~> 4.7.0'

# Awesome Print for pretty printing of Ruby Objects
gem 'awesome_print'

# Use HAML and CoffeeScript for Backbone.JS SPAs
gem 'haml_coffee_assets'
# TODO: Upgrade to Sprockets >= 3.0 when haml_coffee_assets is fixed.
# See: https://github.com/emilioforrer/haml_coffee_assets/issues/152
gem 'sprockets-rails', '2.3.3'

# Validate JSONB columns via JSONschema
gem 'activerecord_json_validator'

# Enhanced `Array#dig` and `Hash#dig` for digging nested array/hash structures.
gem 'ruby_dig2'

group :development do
  # Hint opimization opportunities while developing.
  gem 'bullet'
  # Chrome extension to get meta info for the current request.
  gem 'meta_request', '~> 0.4.0'
  # Generate UML diagrams for the database.
  gem 'railroady'
  # Hints missing indexes.
  gem 'lol_dba'

  # Gems for prettier errors in development
  gem 'better_errors'
  gem 'binding_of_caller'

  # Catching mails and serving them locally via a web interface.
  gem 'letter_opener_web', '~> 1.2.0'
end

group :test do
  gem 'rspec-sidekiq', github: 'velaluqa/rspec-sidekiq', branch: 'deprecate-have-enqueued-job'
end

group :development, :test do
  # Ruby console tool and additional extensions
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-doc'
  gem 'pry-git'
  gem 'pry-stack_explorer'
  gem 'pry-remote'
  gem 'pry-byebug'
  gem 'hirb'

  # Rubocop ensures the ruby style guide.
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter', require: false

  gem 'rails_best_practices'
  # gem 'rails_best_practices-formatter'

  # Rails Security metrics
  gem 'brakeman', require: false

  # Checks the code climate/code smells
  gem 'rubycritic', require: false
  gem 'flog'
  gem 'flay'
  gem 'reek'

  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
  gem 'simplecov-json', require: false
  gem 'simplecov-rcov', require: false
  gem 'yard', require: false
  gem 'yard-activesupport-concern', require: false
  gem 'yard-activerecord', github: 'velaluqa/yard-activerecord', require: false

  gem 'gitdeploy', git: 'ssh://git@git.velalu.qa:53639/velaluqa/gitdeploy.git', branch: :master, require: false

  gem 'yarjuf', '~> 2.0.0'
  gem 'webmock'
  gem 'capybara'
  gem 'poltergeist'
  gem 'database_cleaner'

  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'rspec', '~> 3.4.0'
  gem 'rspec-mocks', '~> 3.4.1'
  gem 'rspec-rails', '~> 3.4.2'
  gem 'with_model', '~> 1.2.1'
  gem 'shoulda-matchers'
  # Spec delegation via ActiveSupport's #delegate method.
  gem 'delegate_matcher'

  gem 'turnip'
  gem 'gherkin', '~> 2.5'

  gem 'guard', '~> 2.13.0'
  gem 'guard-rspec'

  gem 'test-unit'
  gem 'redis-namespace'

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
