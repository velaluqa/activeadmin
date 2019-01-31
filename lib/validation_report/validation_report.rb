require File.expand_path('patches/capybara_screenshot', File.dirname(__FILE__))

require 'fileutils'

module ValidationReport
  def self.setup
    @tmp_path = Rails.root.join('tmp/validation_report')

    FileUtils.rm_rf(@tmp_path)
    FileUtils.mkdir(@tmp_path)
  end

  def self.generate(rspec_example_notifications)
    # Generate report here
    # _notification.notifications[0].example.metadata contains a lot
    # of information
    # Missing: Stepwise screenshot
    byebug
  end

  def self.tmp_path
    @tmp_path
  end
end

require File.expand_path('./rspec/formatter', File.dirname(__FILE__))
require File.expand_path('./rspec/helper', File.dirname(__FILE__))
