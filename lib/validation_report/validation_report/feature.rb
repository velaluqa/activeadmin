module ValidationReport
  class Feature
    attr_reader :turnip_feature, :file_path

    def initialize(turnip_feature:, file_path:)
      @turnip_feature = turnip_feature
      @file_path = file_path
      @scenarios ||= []
    end

    def name
      @turnip_feature.name
    end

    def description
      @turnip_feature.description.strip
    end

    def scenarios
      @scenarios ||= @turnip_feature.scenarios.map do |turnip_scenario|
        Scenario.new(
          turnip_scenario: turnip_scenario,
          turnip_backgrounds: @turnip_feature.backgrounds,
          feature: self
        )
      end
    end
  end
end
