class CreateHistoricReportQueries < ActiveRecord::Migration[4.2]
  def change
    create_table :historic_report_queries do |t|
      t.string :resource_type
      t.string :group_by
      t.timestamps null: false
    end
  end
end
