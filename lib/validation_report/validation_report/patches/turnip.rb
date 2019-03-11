require 'turnip'

module Turnip::RSpec
  class << self
    alias_method :original_run_feature, :run_feature

    def run_feature(context, feature, filename)
      ValidationReport.add_feature(feature: feature, filename: filename)
      original_run_feature(context, feature, filename)
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

      if matches.length == 0
        raise Turnip::Pending, description
      end

      if matches.length > 1
        msg = ['Ambiguous step definitions'].concat(matches.map(&:trace)).join("\r\n")
        raise Turnip::Ambiguous, msg
      end

      if step_or_description.respond_to?(:argument) # Turnip::Node::Step
        step_label = step_or_description.keyword + step_or_description.text
      else # String
        step_label = step_or_description
      end
      ValidationReport.push_step(
        label: step_label,
        source_location: matches.first.step_definition.block.source_location
      )

      send(matches.first.method_name, *(matches.first.params + extra_args))

      ValidationReport.pop_step
    end
  end
end
