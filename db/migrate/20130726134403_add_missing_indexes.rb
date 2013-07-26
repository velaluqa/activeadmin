class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :cases, :assigned_reader_id
    add_index :cases, :current_reader_id
    add_index :cases, :position


    add_index :forms, :session_id

    add_index :roles, :subject_id
    add_index :roles, :subject_type
    add_index :roles, :user_id

    add_index :sessions, :study_id
  end
end
