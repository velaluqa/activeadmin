class Sql
  class Column
    attr_accessor :table_name, :name, :type, :limit, :nullable
    alias_method :nullable?, :nullable

    def initialize(table_name, pg_column, options = {})
      @table_name = table_name
      @name = pg_column.name
      @type = pg_column.type
      @limit = pg_column.limit
      @nullable = pg_column.null
      @override = options[:override]
    end

    def to_s
      %("#{name}")
    end

    def type_postfix(_options = {})
      case type
      when :integer  then '::integer'
      when :string   then "::varchar(#{limit})"
      when :text     then '::text'
      when :datetime then '::timestamp'
      when :date     then '::date'
      else raise "Unknown type for #{self}: #{type}"
      end
    end

    def with_type
      "#{self}#{type_postfix}"
    end

    def with_ref(options = {})
      column = options[:column] ? "\"#{options[:column]}\"" : to_s
      %("#{options[:ref] || table_name}".#{column})
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
      else raise "Unknown type for #{self}: #{type}"
      end
    end

    def format_override(options = {})
      case @override
      when String then
        return "format('%L', '')" if @override.blank?

        vars = @override.scan(/{{:([^}]+)}}/).flatten
        format = "format('%L', format('#{@override.gsub(/{{:([^}]+)}}/, '%s')}', "
        format << vars.map { |var| with_ref(options.merge(column: var)) }.join(', ')
        format << '))'
        format
      when :nil then "format('%L', NULL)"
      end
    end

    def select(options = {})
      if @override
        format_override(options)
      else
        catch_null(options) { format(options) }
      end
    end
  end
end
