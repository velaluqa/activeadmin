source 'https://rubygems.org'

gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'pg'

# MongoDB
gem 'mongoid', '~> 3.0.0'
gem 'bson_ext'

# HAML templating engine
# needs to be added explicitely, otherwise it might not register itself as a templating engine in Rails
gem 'haml'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  gem 'haml-rails'
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'
  gem 'bootstrap-datepicker-rails'

  gem 'uglifier', '>= 1.0.3'
end

# we need these even in production, for server-side judgement functions
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'libv8', '~> 3.11.8'
gem 'therubyracer', :platforms => :ruby
gem 'execjs'

gem 'jquery-rails'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
gem 'debugger'

# authentication/authorization
gem 'devise'
gem 'cancan'

# audit trail
gem 'paper_trail', '~>2'

# ActiveAdmin
gem 'activeadmin', '~>0.5.1', :github => 'profmaad/active_admin', :branch => 'v0.5.1-checkboxtoggler_fix'
gem 'activeadmin-mongoid', :github => 'profmaad/activeadmin-mongoid', :branch => 'master'
gem 'activeadmin-cancan'

# CodeRay for rendering yaml/json data
gem 'coderay'

# Rugged for Git-based config versioning
gem 'rugged', :github => 'libgit2/rugged', :branch => 'development', :submodules => true

# Airbrake Exception notifier
gem 'airbrake'

# Kwalify schema validator
gem 'kwalify'

# diff library for config changes display
gem 'diffy'

# select2 gem for integration with asset pipeline
gem 'select2-rails', :github => 'profmaad/select2-rails', :branch => 'master'

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
gem 'dentaku', :github => 'rubysolo/dentaku', :branch => 'master'

# Sidekiq is used for asynchronous job execution, i.e. DICOM searches, exports, ...
gem 'sidekiq'
# Sidekiq middleware to ensure proper behaviour of mongoid connections in sidekiq workers
gem 'kiqstand'

# Ruby DICOM lib
gem 'dicom'

# MongoDB audit trail
gem 'mongoid-history'

# Zip file creation for image download in ERICA Remote
gem 'rubyzip'

# Resource tagging in ERICA Remote
gem 'acts-as-taggable-on'

gem 'ruby-progressbar'

gem 'andand'

# For the Sidekiq monitoring interface
gem 'slim', '>= 1.1.0'
gem 'sinatra', '>= 1.3.0', :require => nil

group :development do
  # Annotate models, routes, fixtures with describing comments.
  gem 'annotate'
  # Hint opimization opportunities while developing.
  gem 'bullet'
  # Chrome extension to get meta info for the current request.
  gem 'meta_request'
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
  gem 'jazz_hands'

  # Rubocop ensures the ruby style guide.
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter', require: false

  gem 'rails_best_practices'
  # gem 'rails_best_practices-formatter'

  gem 'flog'
  gem 'flay'
  gem 'reek'

  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
  gem 'simplecov-json', require: false
  gem 'simplecov-rcov', require: false
  gem 'rubycritic', require: false
end

group :test do
  gem 'factory_girl'
  gem 'faker'

  gem 'rspec'
  gem 'rspec-rails'
  gem 'yarjuf'

  gem 'webmock'

  gem 'capybara'
  gem 'poltergeist'

  gem 'cucumber', require: false
  gem 'cucumber-rails', require: false

  gem 'guard', '>= 2.0.0'
  gem 'guard-cucumber'
  gem 'guard-rspec'
  gem 'database_cleaner'
end
