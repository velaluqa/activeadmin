module ActiveRecord
  class Base # :nodoc:
    def self.find_by_ref(ref)
      match = ref.match(/^(?<klass>\w+)_(?<id>\d+)$/)
      match[:klass].constantize.find(match[:id])
    end

    def attributes_with_enum_strings
      attributes.map { |col, val|
        [col, defined_enums[col].andand.key(val) || val]
      }.to_h
    end
  end
end
