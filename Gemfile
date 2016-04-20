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
gem 'rails-observers' # https://github.com/rails/rails-observers

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3', '~> 1.3.11'
gem 'pg'

# MongoDB
gem 'mongoid', '~> 5.1.2'

gem 'json', '~> 1.8.3'

# HAML templating engine
# needs to be added explicitely, otherwise it might not register itself as a templating engine in Rails
gem 'haml', '~> 4.0.7'

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
# gem 'jbuilder'

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
gem 'airbrake', require: false

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

# Ruby DICOM lib
gem 'dicom'

# MongoDB audit trail
gem 'mongoid-history', '~> 0.5.0'

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

group :development do
  # Annotate models, routes, fixtures with describing comments.
  gem 'annotate'
  # Hint opimization opportunities while developing.
  gem 'bullet'
  # Chrome extension to get meta info for the current request.
  gem 'meta_request', '~> 0.4.0'
  # Generate UML diagrams for the database.
  gem 'railroady'
  # Hints missing indexes.
  # TODO: needs Ruby >= 2.0.0
  # gem 'lol_dba'

  # Gems for prettier errors in development
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :development, :test do
  gem 'zeus'

  # Ruby console tool and additional extensions
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-doc'
  gem 'pry-git'
  gem 'pry-stack_explorer'
  gem 'pry-remote'
  gem 'pry-byebug'
  gem 'hirb'
  gem 'awesome_print'

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

  gem 'gitdeploy', git: 'ssh://git@git.velalu.qa:53639/velaluqa/gitdeploy.git', branch: :master, require: false

  # Bundler-audit helps finding gems that need to be patched for
  # security. Also it provides recommendations for certain
  # dependencies.
  gem 'bundler-audit'
end

group :development, :test do
  gem 'faker'
  gem 'factory_girl_rails', '~> 4.7.0'
end

group :test do
  gem 'rspec', '~> 3.4.0'
  gem 'rspec-mocks', '~> 3.4.1'
  gem 'rspec-rails', '~> 3.4.2'
  gem 'yarjuf', '~> 2.0.0'

  gem 'webmock'

  gem 'capybara'
  gem 'poltergeist'

  gem 'cucumber', require: false
  gem 'cucumber-rails', require: false

  gem 'guard', '~> 2.13.0'
  gem 'guard-cucumber'
  gem 'guard-rspec'
  gem 'database_cleaner'

  gem 'test-unit'

  gem 'redis-namespace'
end
