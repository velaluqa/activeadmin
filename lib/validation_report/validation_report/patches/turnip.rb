# coding: utf-8
module Turnip
  module RSpec
    class << self
      # Original see: https://github.com/jnicklas/turnip/blob/v3.1.0/lib/turnip/rspec.rb#L79
      def run_feature(context, feature, filename)
        background_steps = feature.backgrounds.map(&:steps).flatten

        feature.scenarios.each do |scenario|
          step_names = (background_steps + scenario.steps).map(&:to_s)
          description = step_names.join(" → ")

          context.describe scenario.name, scenario.metadata_hash do
            instance_eval <<-EOS, filename, scenario.line
              it description do
                ValidationReport.push_feature(feature: feature, filename: filename)
                ValidationReport.push_scenario(feature_filename: filename, scenario: scenario)
                background_steps.each do |step|
                  run_step(filename, step)
                end
                scenario.steps.each do |step|
                  run_step(filename, step)
                end
              end
            EOS
          end
        end
      end
    end

    module Execute
      alias_method :original_run_step, :run_step

      def run_step(feature_file, turnip_step)
        ValidationReport.current_turnip_step = turnip_step
        original_run_step(feature_file, turnip_step)
      end

      def step(step_or_description, *extra_args)
        if step_or_description.respond_to?(:argument) # Turnip::Node::Step
          description = step_or_description.description
          if step_or_description.argument
            extra_args << step_or_description.argument
          end
        else # String
          description = step_or_description
        end

        matches = methods.map do |method|
          next unless method.to_s.start_with?("match: ")
          send(method.to_s, description)
        end.compact

        # CUSTOM CODE START
        if step_or_description.respond_to?(:argument) # Turnip::Node::Step
          step_label = step_or_description.to_s
        else # String
          step_label = step_or_description
        end
        source_location = matches.first &&
                          matches.first.step_definition.block.source_location
        ValidationReport.push_step(
          label: step_label,
          source_location: source_location
        )
        # CUSTOM CODE END

        if matches.length == 0
          raise Turnip::Pending, description
        end

        if matches.length > 1
          msg = ['Ambiguous step definitions'].concat(matches.map(&:trace)).join("\r\n")
          raise Turnip::Ambiguous, msg
        end

        send(matches.first.method_name, *(matches.first.params + extra_args))

        # CUSTOM CODE START
        ValidationReport.mark_current_step_as_passed
        ValidationReport.pop_step
        # CUSTOM CODE END
      end
    end
  end

  module Node
    class Step
      def comparison_hash
        {
          text: text,
          argument: argument.respond_to?(:raw) ? argument.raw : argument
        }
      end
    end
  end
end
