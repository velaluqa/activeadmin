module ActiveRecord
  class Base # :nodoc:
    def self.find_by_ref(ref)
      match = ref.match(/^(?<klass>\w+)_(?<id>\d+)$/)
      match[:klass].constantize.find(match[:id])
    end
  end
end
