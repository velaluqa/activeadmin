def tables
  ActiveRecord::Base.connection.execute <<EOF
SELECT
  c.oid AS oid,
  c.relname AS name,
  d.description AS description
FROM pg_class c
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_description d ON c.oid = d.objoid AND d.objsubid = 0
WHERE
    n.nspname = 'public'
    AND c.relkind = 'r'
EOF
end

# Based on https://stackoverflow.com/questions/109325/postgresql-describe-table/118245#118245
def fetch_attributes(table)
  attributes = []
  ret = ActiveRecord::Base.connection.execute <<EOF
SELECT
    f.attnum AS number,
    f.attname AS name,
    f.attnotnull AS notnull,
    pg_catalog.format_type(f.atttypid,f.atttypmod) AS type,
    CASE
        WHEN p.contype = 'p' THEN 't'
        ELSE 'f'
    END AS primarykey,
    CASE
        WHEN p.contype = 'f' THEN g.relname
    END AS foreignkey,
    CASE
        WHEN p.contype = 'f' THEN h.attname
    END AS foreignkey_field,
    CASE
        WHEN f.atthasdef = 't' THEN d.adsrc
    END AS default,
    descr.description AS description
FROM pg_attribute f
    JOIN pg_class c ON c.oid = f.attrelid
    JOIN pg_type t ON t.oid = f.atttypid
    LEFT JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = f.attnum
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN (SELECT * FROM pg_constraint WHERE contype IN ('p', 'f')) p ON p.conrelid = c.oid AND f.attnum = ANY (p.conkey)
    LEFT JOIN pg_class AS g ON p.confrelid = g.oid
    LEFT JOIN pg_attribute h ON h.attrelid = p.confrelid AND h.attnum = ANY(p.confkey)
    LEFT JOIN pg_description AS descr ON descr.objoid = c.oid AND f.attnum = descr.objsubid
WHERE c.relkind = 'r'::char
    AND n.nspname = 'public'  -- Replace with Schema name
    AND c.relname = '#{table}'  -- Replace with table name
    AND f.attnum > 0
ORDER BY number
EOF
  ret.each { |row| attributes.push(row) }
  attributes
end

def fetch_indexes(table_oid, attnum)
  ret = ActiveRecord::Base.connection.execute <<EOF
SELECT
    indkey
FROM pg_index
WHERE
    indrelid = #{table_oid}
    AND #{attnum} = ANY(indkey)
    AND indisunique = 't'
EOF
  indexes = []
  ret.each do |index|
    indkeys = index['indkey'].split(' ').map { |x| Integer(x) }
    indkeys.delete(attnum)
    indexes.push(indkeys)
  end
  indexes
end

namespace :db do
  namespace :schema do
    task document: [:environment] do
      puts "# Database Schema Documentation\n\n"
      puts <<~TEXT

      TEXT
      tables.sort_by { |t| t['name'] }.each do |table|
        next if ['ar_internal_metadata', 'schema_migrations'].include?(table['name'])
        puts "## #{table['name'].camelcase}\n\n"
        puts "#{table['description']}\n" unless table['description'].blank?
        attributes = fetch_attributes(table['name'])
        attributes.sort_by { |a| a['name'] }.each do |attribute|
          puts "### #{attribute['name']}\n\n"
          unless attribute['description'].blank?
            puts "#{attribute['description']}\n"
          end
          puts "| Property | Value |"
          puts "| ------ | ------ |"
          puts "| `Type` | `#{attribute['type']}` |"
          if attribute['notnull']
            puts "| `Nullable` | No |"
          else
            puts "| `Nullable` | Yes |"
          end
          if attribute['primarykey'] == 't'
            puts "| `Primary Key` | Yes |"
          else
            puts "| `Primary Key` | No |"
          end
          indexes = fetch_indexes(table['oid'], attribute['number'])
          indexes.each do |indkeys|
            $stdout << "| `Unique` | "
            if indkeys.empty?
              $stdout << "Yes"
            else
              $stdout << "Together with "
              $stdout << indkeys.map do |indkey|
                attributes.find { |attr| attr['number'] == indkey.to_s }['name']
              end.join(' and ')
            end
            puts " |"
          end
          default_value =
            if attribute['default'].present?
              "`#{attribute['default']}`"
            else
              '_(none)_'
            end
          puts "| `Default Value` | #{default_value} |"
          unless attribute['foreignkey'].blank?
            fk = attribute['foreignkey'].camelcase +
                 '#' +
                 attribute['foreignkey_field']
            puts "| `Foreign Key` | #{fk} |"
          end
          puts "\n"
        end
      end
    end
  end
end
