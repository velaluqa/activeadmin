class Sql
  class Column
    attr_accessor :table_name, :name, :type, :limit, :nullable
    alias_method :nullable?, :nullable

    def initialize(table_name, pg_column)
      @table_name = table_name
      @name = pg_column.name
      @type = pg_column.type
      @limit = pg_column.limit
      @nullable = pg_column.null
    end

    def to_s
      %("#{name}")
    end

    def type_postfix(options = {})
      case type
      when :integer  then '::integer'
      when :string   then "::varchar(#{limit})"
      when :text     then '::text'
      when :datetime then '::timestamp'
      when :date     then '::date'
      else fail "Unknown type for #{self}: #{type}"
      end
    end

    def with_type
      "#{self}#{type_postfix}"
    end

    def with_ref(options = {})
      %("#{options[:ref] || table_name}".#{self})
    end

    def with_reftype(options = {})
      %("#{options[:ref] || table_name}".#{with_type})
    end

    def catch_null(options = {})
      return yield unless nullable?
      "CASE WHEN #{with_ref(options)} IS NULL THEN 'NULL' ELSE #{yield} END"
    end

    def format(options = {})
      case type
      when :integer  then "#{with_ref(options)}::text"
      when :string   then "format('%L', #{with_ref(options)})"
      when :text     then "format('%L', #{with_ref(options)})"
      when :datetime then "format('%L', #{with_ref(options)})||'#{type_postfix(options)}'"
      when :date     then "format('%L', #{with_ref(options)})||'#{type_postfix(options)}'"
      else fail "Unknown type for #{self}: #{type}"
      end
    end

    def select(options = {})
      catch_null(options) { format(options) }
    end
  end
end
