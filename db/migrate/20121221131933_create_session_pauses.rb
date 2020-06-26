class CreateSessionPauses < ActiveRecord::Migration[4.2]
  def change
    create_table :session_pauses do |t|
      t.datetime :start
      t.datetime :end
      t.string :reason
      t.integer :session_id

      t.timestamps null: true
    end
  end
end
