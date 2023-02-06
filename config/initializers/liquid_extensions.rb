Rails.application.config.to_prepare do
  require 'liquid/filters/link_filter'
  require 'liquid/filters/simple_format_filter'
end