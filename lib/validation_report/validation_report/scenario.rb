module ValidationReport
  class Scenario
    def initialize(turnip_scenario:, turnip_backgrounds:, feature:)
      @turnip_scenario = turnip_scenario
      @turnip_backgrounds = turnip_backgrounds
      @feature = feature
    end

    def steps
      @steps ||= begin
        steps = (@turnip_backgrounds.map(&:steps).flatten +
            @turnip_scenario.steps).map do |turnip_step|
          turnip_step.instance_eval { @root_step }
        end
        steps.compact!
        steps
      end
    end

    def name
      @turnip_scenario.name
    end

    def last_change_version
      versions = [last_change_version_of_step_definitions, change_version]
      if versions.include?(:unreleased)
        return :unreleased
      end

      versions.sort!
      versions.last
    end

    # @return [Gem::Version, Symbol] last change version or :unreleased
    def last_change_version_of_step_definitions
      step_versions = steps.map(&:change_version)

      if step_versions.include?(:unreleased)
        return :unreleased
      end

      step_versions.sort!
      step_versions.last
    end

    # Calculates change version for scenario definition
    #
    # @return [Gem::Version, Symbol] last change version or :unreleased
    def change_version
      current_hash = comparison_hash(@feature.turnip_feature)
      versions = ValidationReport.versions

      0.upto(versions.length - 1) do |i|
        version = versions[i]
        temp_file = Tempfile.new('w')
        temp_file << `git show #{version}:#{@feature.file_path} 2>&1`
        temp_file.close
        begin
          older_feature = Turnip::Builder.build(temp_file)
          older_hash = comparison_hash(older_feature)
        rescue Gherkin::ParserError
          older_hash = nil
        end
        temp_file.delete
        if older_hash.nil? || current_hash != older_hash
          if i == 0
            return :unreleased
          else
            return versions[i - 1]
          end
        end
      end

      if versions.empty?
        :unreleased
      else
        versions.last
      end
    end

    private
    def comparison_hash(turnip_feature)
      hash = { steps: [], examples: [] }
      turnip_feature.children.select do |child|
        if child.is_a?(Turnip::Node::Background)
          hash[:steps] += child.steps
        end

        next unless child.name == name

        if child.is_a?(Turnip::Node::ScenarioDefinition)
          hash[:steps] += child.steps
        end

        if child.is_a?(Turnip::Node::ScenarioOutline)
          child.examples.each do |example|
            hash[:examples] << { header: example.header, rows: example.rows}
          end
        end
      end

      hash[:steps].map!(&:comparison_hash)
      hash
    end
  end
end
