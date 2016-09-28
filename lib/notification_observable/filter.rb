module NotificationObservable
  class Filter
    attr_reader :filters

    def initialize(filters)
      @filters = filters.map do |conditions|
        conditions.map do |condition|
          condition.deep_symbolize_keys
        end
      end
    end

    # Returns true if the given attribute or relation conditions matches.
    #
    # @param [ActiveRecord::Base] model The model to match the
    #   condition against
    # @param [Hash] changes Changes in the form of `{ attribute:['oldVal', 'newVal]}`
    # @return [Boolean] Whether the condition matched or not.
    def match?(model, changes = {})
      return true if filters.empty?
      filters.map do |conditions|
        conditions.map do |condition|
          match_condition(condition, model, changes)
        end.all?
      end.any?
    end

    # Returns true if the given attribute or relation conditions matches.
    #
    # @param [Hash] condition The condition to match
    # @param [ActiveRecord::Base] model The model to match the
    #   condition against
    # @param [Hash] changes Changes in the form of `{ attribute:['oldVal', 'newVal]}`
    # @return [Boolean] Whether the condition matched or not.
    def match_condition(condition, model, changes = {})
      attr, cond = condition.first
      if model.has_attribute?(attr)
        match_attribute(attr.to_s, cond, model, changes)
      else
        match_relation(model, attr, cond)
      end
    end

    # Returns true if change filter matches given attribute.
    #
    # @param [String] attr Name of the attribute
    # @param [Hash] condition Condition for the given attribute
    # @param [ActiveRecord::Base] model The attribute's model
    # @param [Hash] changes The changes to filter
    def match_attribute(attr, condition, model, changes = {})
      condition.map do |name, filter|
        case name
        when :equal then model.attributes[attr] == filter
        when :notEqual then model.attributes[attr] != filter
        when :changes then match_change(attr, filter, previous_attributes(model, changes), model.attributes)
        else false
        end
      end.all?
    end

    # Returns true if change filter matches given attribute.
    #
    # @param [String] attr Name of the attribute
    # @param [Hash] changes Changes with `:from` and/or `:to` keys
    # @param [Hash] old Old model attributes
    # @param [Hash] new New model attributes
    def match_change(attr, changes, old, new)
      return old[attr] != new[attr] if changes == true
      return old[attr] == new[attr] if changes == false
      changes.map do |key, value|
        case key
        when :from then old[attr] == value && old[attr] != new[attr]
        when :to then new[attr] == value && old[attr] != new[attr]
        end
      end.all?
    end

    # Returns true if the relation condition matches. That might be,
    # when a relation exists or does not exists, or a related record
    # matching a given filter value exists.
    #
    # @param [ActiveRecord::Base] model The model to match the
    #   relations for.
    # @param [Symbol] key The name of the assiciation.
    # @param [Hash] condition The condition for the relation (nested
    #   relation, existence or matching existence.)
    # @return [Boolean] Whether the condition matches or not.
    def match_relation(model, key, condition)
      relation = model.class
        .joins(relation_joins(key, condition))
        .where(id: model.id)
      table_name, attr, expected, equal = relation_condition(model, key, condition)
      if attr
        if equal
          relation.where(%("#{table_name}"."#{attr}" = ?), expected).exists?
        else
          relation.where(%("#{table_name}"."#{attr}" != ?), expected).exists?
        end
      else
        relation.where(%("#{table_name}"."id" IS NOT NULL)).exists? == expected
      end
    end

    # Returns hash structure for ActiveRecords `#joins` method.
    #
    # @param [Symbol] key The name of the assiciation.
    # @param [Hash] condition The condition for the relation (nested
    #   relation, existence or matching existence.)
    # @return [Symbol, Hash] The join structure.
    def relation_joins(key, condition)
      return nil if condition.is_a?(Hash) && (condition.key?(:equal) || condition.key?(:notEqual))
      return key if condition == true || condition == false
      sub = relation_joins(*condition.first)
      return key unless sub
      { key => sub }
    end

    def relation_condition(model, key, condition)
      ret = relation_equality_condition(model, key, condition) and return ret
      relation_existance_condition(model, key, condition)
    end

    # Creates a String in the form "attribute(from => to)" from the
    # `triggering_changes` Array. Array elements are logically disjunct
    # and all hash keys are logically conjunct.
    def to_s
      return if filters.empty?
      conjs = filters.map do |conditions|
        conditions.map do |key, t|
          "#{key}(#{t.fetch(:from, '*any*')} => #{t.fetch(:to, '*any*')})"
        end.join(' AND ')
      end
      conjs.map! { |conj| conj.include?('AND') ? "(#{conj})" : conj }
      conjs.join(' OR ')
    end

    private

    def relation_equality_condition(model, key, condition)
      return unless condition.is_a?(Hash)
      return [model.table_name, key, condition[:equal], true] if condition.key?(:equal)
      return [model.table_name, key, condition[:notEqual], false] if condition.key?(:notEqual)
    end

    def relation_existance_condition(model, key, condition)
      model = model._reflections[key.to_s].klass
      return [model.table_name, nil, condition, nil] if condition == true || condition == false
      relation_condition(model, *condition.first)
    end

    def previous_attributes(model, changes)
      attributes = model.attributes
      changes.each_pair do |key, value|
        attributes[key.to_s] = value[0] if attributes[key.to_s] == value[1]
      end
      attributes
    end
  end
end
