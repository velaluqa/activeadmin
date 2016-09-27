module NotificationObservable
  class Filter
    attr_reader :filters

    def initialize(filters)
      @filters = filters
    end

    def match?(model, changes = {})
      filters.map do |conditions|
        conditions.map do |condition|
          match_condition(condition, model, changes)
        end.all?
      end.any?
    end

    def match_condition(condition, model, changes = {})
      attr, cond = condition.first
      if model.has_attribute?(attr)
        match_attribute(attr.to_s, cond, model, changes)
      else
        match_relation(model, attr.to_s, cond)
      end
    end

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

    def relation_joins(key, condition)
      return nil if condition.is_a?(Hash) && (condition.key?(:equal) || condition.key?(:notEqual))
      return key.to_sym if condition == true || condition == false
      sub = relation_joins(*condition.first)
      return key.to_sym unless sub
      { key.to_sym => sub }
    end

    def relation_condition(model, key, condition)
      key = key.to_s
      ret = relation_equality_condition(model, key, condition) and return ret
      relation_existance_condition(model, key, condition)
    end

    def match_change(attr, change, old, new)
      return old[attr] != new[attr] if change == true
      return old[attr] == new[attr] if change == false
      change.map do |key, value|
        case key
        when :from then old[attr] == value && old[attr] != new[attr]
        when :to then new[attr] == value && old[attr] != new[attr]
        end
      end.all?
    end

    private

    def relation_equality_condition(model, key, condition)
      return unless condition.is_a?(Hash)
      return [model.table_name, key, condition[:equal], true] if condition.key?(:equal)
      return [model.table_name, key, condition[:notEqual], false] if condition.key?(:notEqual)
    end

    def relation_existance_condition(model, key, condition)
      model = model._reflections[key].klass
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
