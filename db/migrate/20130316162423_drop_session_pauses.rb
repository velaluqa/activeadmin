class DropSessionPauses < ActiveRecord::Migration
  def up
    drop_table :session_pauses
  end

  def down
    create_table 'session_pauses' do |t|
      t.datetime 'start'
      t.datetime 'end'
      t.string   'reason'
      t.integer  'session_id'
      t.datetime 'created_at',   null: false
      t.datetime 'updated_at',   null: false
      t.integer  'last_view_id'
    end
  end
end
