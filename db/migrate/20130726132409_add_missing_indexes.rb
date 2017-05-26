class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :cases, :assigned_reader_id
    add_index :cases, :current_reader_id
    add_index :cases, :position

    add_index :centers, :study_id

    add_index :forms, :session_id

    add_index :image_series, :visit_id
    add_index :image_series, :patient_id
    add_index :image_series, :series_number

    add_index :images, :image_series_id

    add_index :patients, :center_id

    add_index :roles, :subject_id
    add_index :roles, :subject_type
    add_index :roles, :user_id

    add_index :sessions, :study_id

    add_index :visits, :patient_id
    add_index :visits, :visit_number
    add_index :visits, :mqc_user_id
  end
end
