require 'remote/sql/column'

module Sql
  class Dumper
    attr_accessor :relation, :table_name, :columns

    def initialize(relation, options = {})
      @relation = relation

      @insert_columns = options[:insert_columns]
      @update_columns = options[:update_columns]
      @ignore_insert_columns = options[:ignore_insert_columns]
      @ignore_update_columns = options[:ignore_update_columns]

      @table_name = @relation.table_name
      @columns = @relation.columns.clone
      @columns.map! { |column| SqlColumn.new(table_name, column) }
      @columns.sort_by!(&:name)
    end

    def update_columns
      @update_columns || columns
    end

    def insert_columns
      @insert_columns || columns
    end

    def new_values_select
      sql_concat = '||\', \'||'
      "'('||" + columns.map(&:select).join(sql_concat) + "||')'"
    end

    def new_values
      query = @relation
              .select(new_values_select)
              .order("\"#{table_name}\".\"id\"")
      ActiveRecord::Base.connection.select_values(query).join(",\n")
    end

    def update_setters
      update_columns
        .map { |column| "#{column} = #{column.with_reftype(ref: 'nv')}" }
        .join(",\n    ")
    end

    def dump_upserts(io)
      io << <<SQL
WITH "new_values" (#{columns.map(&:to_s).join(', ')}) as (
  values
#{new_values}
),
"upsert" AS
(
  UPDATE "#{table_name}" "m"
  SET
    #{update_setters}
  FROM "new_values" "nv"
  WHERE "m"."id" = "nv"."id"
  RETURNING "m".*
)
INSERT INTO "#{table_name}" (#{insert_columns.map(&:to_s).join(', ')})
SELECT #{insert_columns.map(&:with_type).join(', ')}
FROM "new_values"
WHERE NOT EXISTS (SELECT 1 FROM "upsert" "up" WHERE "up"."id" = "new_values"."id")
SQL
    end
  end
end
