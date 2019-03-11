module ValidationReport
  class Scenario
    def initialize(turnip_scenario:, turnip_backgrounds:)
      @turnip_scenario = turnip_scenario
      @turnip_backgrounds = turnip_backgrounds
    end

    def steps
      @steps ||= (@turnip_backgrounds.map(&:steps).flatten +
                  @turnip_scenario.steps).map do |turnip_step|
        turnip_step.instance_eval { @root_step }
      end
    end

    def name
      @turnip_scenario.name
    end

    # @return [Gem::Version, Symbol] last change version or :unreleased
    def last_change_version_of_step_definitions
      step_versions = steps.map(&:last_change_version)

      if step_versions.include?(:unreleased)
        return :unreleased
      end

      step_versions.sort!
      step_versions.last
    end
  end
end
