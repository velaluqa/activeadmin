module Migration
  class ReorderVersionIds # :nodoc:
    class << self
      def run
        ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
          ALTER TABLE versions DROP CONSTRAINT versions_pkey;
          DROP INDEX IF EXISTS index_versions_reorder_by_timestamp;
          CREATE INDEX IF NOT EXISTS index_versions_reorder_by_timestamp ON versions (created_at, id);
          CLUSTER versions USING index_versions_reorder_by_timestamp;
          SELECT setval('versions_id_seq', 1);
          UPDATE versions SET id=nextval('versions_id_seq');
          ALTER TABLE versions ADD CONSTRAINT versions_pkey PRIMARY KEY (id);
          CLUSTER versions USING versions_pkey;
        SQL
      end
    end
  end
end
