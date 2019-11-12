require 'remote/sql/column'

class Sql
  class Dumper
    attr_accessor :relation, :table_name, :columns

    def initialize(relation, options = {})
      @relation = relation

      @insert_columns = Array(options[:insert_columns]).flatten
      @update_columns = Array(options[:update_columns]).flatten
      @ignore_insert_columns = Array(options[:ignore_insert_columns]).flatten
      @ignore_update_columns = Array(options[:ignore_update_columns]).flatten

      @table_name = @relation.table_name
      @columns = @relation.columns.clone
      unless Array(options[:columns]).flatten.empty?
        @columns.select! { |col| options[:columns].include?(col.name.to_s) }
      end
      @columns.map! do |column|
        Sql::Column.new(
          table_name,
          column,
          override: options[:override_values]
            .andand.stringify_keys
            .andand[column.name]
        )
      end
      @columns.sort_by!(&:name)
    end

    # Columns used when updating an existing dataset.
    def update_columns
      cols = columns.map(&:name).map(&:to_s)
      cols &= @update_columns unless @update_columns.empty?
      cols -= @ignore_update_columns unless @ignore_update_columns.empty?
      columns.select { |col| cols.include?(col.name.to_s) }
    end

    # Columns used when inserting a new dataset.
    def insert_columns
      cols = columns.map(&:name).map(&:to_s)
      cols &= @insert_columns unless @insert_columns.empty?
      cols -= @ignore_insert_columns unless @ignore_insert_columns.empty?
      columns.select { |col| cols.include?(col.name.to_s) }
    end

    def new_values_select
      sql_concat = '||\', \'||'
      "'('||" + columns.map(&:select).join(sql_concat) + "||')'"
    end

    def new_values
      query = @relation
              .select(new_values_select)
              .order(Arel.sql("\"#{table_name}\".\"id\""))
      ActiveRecord::Base.connection.select_values(query)
    end

    def update_setters
      update_columns
        .map { |column| "#{column} = #{column.with_reftype(ref: 'nv')}" }
        .join(",\n              ")
    end

    def dump_upserts(io)
      io.puts 'BEGIN;'
      new_values.each_slice(25_000) do |new_values|
        io.puts <<-SQL.strip_heredoc
          WITH "new_values" (#{columns.map(&:to_s).join(', ')}) as (
            values
          #{new_values.join(",\n          ")}
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
          WHERE NOT EXISTS (SELECT 1 FROM "upsert" "up" WHERE "up"."id" = "new_values"."id");
        SQL
      end
      io.puts 'COMMIT;'
    end
  end
end
