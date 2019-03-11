require File.expand_path('validation_report/feature', File.dirname(__FILE__))
require File.expand_path('validation_report/scenario', File.dirname(__FILE__))
require File.expand_path('validation_report/step', File.dirname(__FILE__))
require File.expand_path('validation_report/screenshot', File.dirname(__FILE__))

require 'fileutils'

module ValidationReport
  def self.initialize
    @features = []
    @current_step = nil
  end

  def self.setup
    @tmp_path = Rails.root.join('tmp/validation_report')
    FileUtils.rm_rf(Dir[@tmp_path.join('*')])
    FileUtils.mkdir_p(@tmp_path)
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
    md << '# Automated Validation Report for ' +
          "#{application_name} #{application_version}\n"
    md << "\n## Version History\n\n"
    versions.each do |version|
      md << "* #{version}\n"
    end
    md << "\n## Automated Feature Validation\n\n"
    @features.sort(&:file_path).each do |feature|
      md << "### #{feature.name}\n\n"
      md << "#{feature.description}\n"
      feature.scenarios.each do |scenario|
        md << "\n#### #{feature.name} :: #{scenario.name}\n\n"
        v = scenario.last_change_version
        if v == :unreleased
          md << "Scenario definition unreleased\n"
        else
          md << "Scenario definition changed with version #{v}\n"
        end
        v = scenario.last_change_version_of_step_definitions
        if v == :unreleased
          md << "Step definitions unreleased\n"
        else
          md << "Step definitions changed with version #{v}\n"
        end
        scenario.steps.each do |step|
          if step.nil?
            md << "\nSTEP OMITTED\n"
          else
            md << step.report_markdown(indent_level: 5)
          end
        end
      end
    end
    md.close
  end
end

ValidationReport.initialize

require File.expand_path('validation_report/rspec/formatter', File.dirname(__FILE__))
require File.expand_path('validation_report/rspec/helper', File.dirname(__FILE__))
require File.expand_path('validation_report/patches/capybara_screenshot', File.dirname(__FILE__))
require File.expand_path('validation_report/patches/turnip', File.dirname(__FILE__))
