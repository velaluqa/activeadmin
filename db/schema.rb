# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160419081900) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "background_jobs", force: :cascade do |t|
    t.string   "legacy_id"
    t.integer  "user_id"
    t.boolean  "completed",     default: false, null: false
    t.float    "progress",      default: 0.0,   null: false
    t.datetime "completed_at"
    t.boolean  "successful"
    t.text     "error_message"
    t.jsonb    "results",       default: {},    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "background_jobs", ["completed"], name: "index_background_jobs_on_completed", using: :btree
  add_index "background_jobs", ["legacy_id"], name: "index_background_jobs_on_legacy_id", using: :btree
  add_index "background_jobs", ["results"], name: "index_background_jobs_on_results", using: :gin
  add_index "background_jobs", ["user_id"], name: "index_background_jobs_on_user_id", using: :btree

  create_table "cases", force: :cascade do |t|
    t.integer  "position"
    t.integer  "session_id"
    t.integer  "patient_id"
    t.string   "images"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "case_type"
    t.integer  "state",                           default: 0
    t.integer  "flag",                            default: 0
    t.datetime "exported_at"
    t.boolean  "no_export",                       default: false
    t.string   "comment"
    t.integer  "assigned_reader_id"
    t.integer  "current_reader_id"
    t.boolean  "is_adjudication_background_case", default: false
  end

  add_index "cases", ["assigned_reader_id"], name: "index_cases_on_assigned_reader_id", using: :btree
  add_index "cases", ["current_reader_id"], name: "index_cases_on_current_reader_id", using: :btree
  add_index "cases", ["patient_id"], name: "index_cases_on_patient_id", using: :btree
  add_index "cases", ["position"], name: "index_cases_on_position", using: :btree
  add_index "cases", ["session_id", "position"], name: "index_cases_on_session_id_and_position", unique: true, using: :btree
  add_index "cases", ["session_id"], name: "index_cases_on_session_id", using: :btree

  create_table "centers", force: :cascade do |t|
    t.string   "name"
    t.integer  "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code"
    t.string   "domino_unid"
  end

  add_index "centers", ["study_id", "code"], name: "index_centers_on_study_id_and_code", unique: true, using: :btree
  add_index "centers", ["study_id"], name: "index_centers_on_study_id", using: :btree

  create_table "forms", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "session_id"
    t.integer  "state",          default: 0
    t.string   "locked_version"
  end

  add_index "forms", ["session_id"], name: "index_forms_on_session_id", using: :btree

  create_table "image_series", force: :cascade do |t|
    t.string   "name"
    t.integer  "visit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "patient_id"
    t.date     "imaging_date"
    t.string   "domino_unid"
    t.integer  "series_number"
    t.integer  "state",         default: 0
    t.string   "comment"
  end

  add_index "image_series", ["patient_id", "series_number"], name: "index_image_series_on_patient_id_and_series_number", unique: true, using: :btree
  add_index "image_series", ["patient_id"], name: "index_image_series_on_patient_id", using: :btree
  add_index "image_series", ["series_number"], name: "index_image_series_on_series_number", using: :btree
  add_index "image_series", ["visit_id"], name: "index_image_series_on_visit_id", using: :btree

  create_table "images", force: :cascade do |t|
    t.integer  "image_series_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "images", ["image_series_id"], name: "index_images_on_image_series_id", using: :btree

  create_table "patients", force: :cascade do |t|
    t.string   "subject_id"
    t.string   "images_folder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "center_id"
    t.string   "domino_unid"
    t.jsonb    "data",           default: {}, null: false
    t.jsonb    "export_history", default: [], null: false
  end

  add_index "patients", ["center_id"], name: "index_patients_on_center_id", using: :btree

  create_table "public_keys", force: :cascade do |t|
    t.integer  "user_id",        null: false
    t.text     "public_key",     null: false
    t.boolean  "active",         null: false
    t.datetime "deactivated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "public_keys", ["active"], name: "index_public_keys_on_active", using: :btree
  add_index "public_keys", ["user_id"], name: "index_public_keys_on_user_id", using: :btree

  create_table "readers_sessions", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "session_id"
  end

  add_index "readers_sessions", ["user_id", "session_id"], name: "index_readers_sessions_on_user_id_and_session_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.integer  "subject_id"
    t.string   "subject_type"
    t.integer  "user_id"
    t.integer  "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["subject_id"], name: "index_roles_on_subject_id", using: :btree
  add_index "roles", ["subject_type"], name: "index_roles_on_subject_type", using: :btree
  add_index "roles", ["user_id"], name: "index_roles_on_user_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "name"
    t.integer  "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "state",          default: 0
    t.string   "locked_version"
  end

  add_index "sessions", ["study_id"], name: "index_sessions_on_study_id", using: :btree

  create_table "studies", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locked_version"
    t.string   "domino_db_url"
    t.string   "notes_links_base_uri"
    t.string   "domino_server_name"
    t.integer  "state",                default: 0
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "public_key"
    t.text     "private_key"
    t.string   "username"
    t.datetime "password_changed_at"
    t.string   "authentication_token"
    t.integer  "failed_attempts",        default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "validators_sessions", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "session_id"
  end

  add_index "validators_sessions", ["user_id", "session_id"], name: "index_validators_sessions_on_user_id_and_session_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.datetime "created_at"
    t.jsonb    "object"
    t.jsonb    "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "visits", force: :cascade do |t|
    t.integer  "visit_number"
    t.string   "visit_type"
    t.integer  "patient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "domino_unid"
    t.string   "description"
    t.datetime "mqc_date"
    t.integer  "mqc_user_id"
    t.integer  "state",        default: 0
    t.integer  "mqc_state",    default: 0
  end

  add_index "visits", ["mqc_user_id"], name: "index_visits_on_mqc_user_id", using: :btree
  add_index "visits", ["patient_id"], name: "index_visits_on_patient_id", using: :btree
  add_index "visits", ["visit_number"], name: "index_visits_on_visit_number", using: :btree

end
