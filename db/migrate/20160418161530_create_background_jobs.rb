class CreateBackgroundJobs < ActiveRecord::Migration
  def change
    create_table :background_jobs do |t|
      t.string :legacy_id
      t.integer :user_id, null: true
      t.boolean :completed, null: false, default: false
      t.float :progress, null: false, default: 0.0
      t.datetime :completed_at
      t.boolean :successful
      t.text :error_message
      t.jsonb :results, null: false, default: '{}'

      t.timestamps null: true
    end
    add_index :background_jobs, :legacy_id
    add_index :background_jobs, :user_id
    add_index :background_jobs, :completed
    add_index :background_jobs, :results, using: :gin
  end
end
