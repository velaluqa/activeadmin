require 'simplecov'
require 'simplecov-json'
require 'simplecov-rcov'
require 'simplecov-cobertura'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter,
  SimpleCov::Formatter::RcovFormatter
]

SimpleCov.start 'rails' do
  merge_timeout 1200
  add_filter 'spec/'
  add_filter 'config/'
  add_filter 'vendor/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Views', 'app/views'
  add_group 'ActiveAdmin', 'app/admin'
  add_group 'Workers', 'app/workers'
  add_group 'Library', 'lib'
end
