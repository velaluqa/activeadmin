# coding: utf-8
require File.expand_path('validation_report/feature', File.dirname(__FILE__))
require File.expand_path('validation_report/scenario', File.dirname(__FILE__))
require File.expand_path('validation_report/step', File.dirname(__FILE__))
require File.expand_path('validation_report/screenshot', File.dirname(__FILE__))
require File.expand_path('validation_report/rspec/helper', File.dirname(__FILE__))

require 'fileutils'

module ValidationReport
  extend RSpec::Helper

  def self.initialize
    @features = []
    @current_step = nil
  end

  def self.setup
    @tmp_path = Rails.root.join('tmp/validation_report')
    FileUtils.rm_rf(Dir[@tmp_path.join('*')])
    FileUtils.mkdir_p(@tmp_path)

    ::RSpec.configure do |config|
      config.after(type: :feature) do |example|
        # In case of a failure, @current_step is not nil, and we add a
        # screenshot, to ensure we get a screenshot for a failing step.
        ValidationReport.ensure_screenshot
      end
    end
  end

  def self.enabled?
    !@tmp_path.nil?
  end

  def self.tmp_path
    @tmp_path
  end

  def self.add_feature(feature:, filename:)
    @features << Feature.new(
      turnip_feature: feature,
      file_path: Pathname.new(filename).relative_path_from(Rails.root)
    )
  end

  def self.current_turnip_step=(turnip_step)
    @current_turnip_step = turnip_step
    @current_step = nil
  end

  def self.push_step(*args)
    step = Step.new(*args)
    if @current_step.nil?
      step.turnip_step = @current_turnip_step
      @current_turnip_step.instance_eval { @root_step = step }
      @current_scenario = @features.last.scenarios.find do |scenario|
        scenario.steps.include?(step)
      end
    else
      @current_step.add_substep(step)
    end
    @current_step = step
  end

  def self.pop_step
    @current_step = @current_step.parent_step
  end

  def self.attach_screenshot(image_path)
    @current_step.add_screenshot(Screenshot.new(path: image_path))
  end

  def self.ensure_screenshot
    @current_step && validation_report_screenshot
  end

  def self.mark_current_step_as_passed
    @current_step.mark_as_passed
  end

  def self.mark_current_scenario_as_passed
    @current_scenario.mark_as_passed
  end

  def self.versions
    @versions ||= begin
       versions = `git tag -l`.split("\n").map! do |v|
         begin
           Gem::Version.new(v)
         rescue
           # the tag might not be of correct version format
           # in those cases we simply ignore the tag (remove them by compact!)
           nil
         end
       end
       versions.compact!
       versions.sort!
       versions.reverse!
       versions
    end
  end

  def self.generate(rspec_example_notifications)
    application_name = Rails.application.class.parent_name
    application_version = `git describe --tags 2>&1`.strip

    # Generate markdown
    md = File.open(@tmp_path.join('validation_report.md'), 'w')
    md << '<style type="text/css">'
    md << File.read(File.join(File.dirname(__FILE__), 'style.css'))
    md << '</style>'
    md << '# Automated Validation Report for ' +
          "#{application_name} #{application_version}\n"
    md << "\n## Version History\n\n"
    versions.each do |version|
      md << "* #{version}\n"
    end
    md << "\n## Automated Feature Validation\n\n"
    @features.sort(&:file_path).each do |feature|
      md << "### #{feature.name}\n\n"
      md << "```\n  #{feature.description}\n```\n"
      md << "\n<table class=\"scenarios\">\n<tr>\n<th>" +
            [
              'Scenario',
              'Step',
              'Screenshot',
              'Passed',
              'Last Change Version',
              'Date',
              'Signature'
            ].join("</th>\n<th>") +
            "</th>\n</tr>\n"
      feature.scenarios.each do |scenario|
        md << "<tr>\n" +
              [
                "<td colspan=\"3\">#{scenario.name}</td>\n",
                scenario.passed? ? "<td class=\"passed\">✓</td>" : "<td class=\"failed\">✕</td>",
                "<td>#{scenario.last_change_version}</td>\n",
                "<td></td>\n",
                "<td></td>\n",
              ].join +
              "</tr>\n"
        scenario.steps.each do |step|
          md << step.report_html_row
        end
      end
      md << "</table>\n"
    end
    md.close
  end
end

ValidationReport.initialize

require File.expand_path('validation_report/rspec/formatter', File.dirname(__FILE__))
require File.expand_path('validation_report/patches/capybara_screenshot', File.dirname(__FILE__))
require File.expand_path('validation_report/patches/turnip', File.dirname(__FILE__))
