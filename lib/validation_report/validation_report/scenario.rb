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
  end
end
