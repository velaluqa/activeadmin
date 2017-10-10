class AddVersionsRequiredSeriesIndex < ActiveRecord::Migration
  def change
    execute('CREATE INDEX idx_on_versions_rs_changes1 ON versions ((object ->> \'name\'))')
    execute('CREATE INDEX idx_on_versions_rs_changes2 ON versions ((object ->> \'visit_id\'))')
    execute('CREATE INDEX idx_on_versions_rs_changes3 ON versions ((object_changes #>> \'{name,1}\'))')
    execute('CREATE INDEX idx_on_versions_rs_changes4 ON versions ((object_changes #>> \'{visit_id,1}\'))')
  end
end
