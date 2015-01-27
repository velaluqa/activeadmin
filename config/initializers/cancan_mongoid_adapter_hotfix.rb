# Original code is in /cancan-1.6.9/lib/cancan/model_adapters/mongoid_adapter.rb
# The only change is changing 'records.or rule.conditions' to 'records.or rule.conditions.selector'

module CanCan
  module ModelAdapters
    class MongoidAdapter < AbstractAdapter
      def database_records
        if @rules.size == 0
          @model_class.where(:_id => {'$exists' => false, '$type' => 7}) # return no records in Mongoid
        elsif @rules.size == 1 && @rules[0].conditions.is_a?(Mongoid::Criteria)
          @rules[0].conditions
        else
          # we only need to process can rules if
          # there are no rules with empty conditions
          rules = @rules.reject { |rule| rule.conditions.empty? && rule.base_behavior }
          process_can_rules = @rules.count == rules.count

          rules.inject(@model_class.all) do |records, rule|
            if process_can_rules && rule.base_behavior
              records.or rule.conditions.selector
            elsif !rule.base_behavior
              records.excludes rule.conditions
            else
              records
            end
          end
        end
      end
    end
  end
end
