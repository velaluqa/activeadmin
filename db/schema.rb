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

ActiveRecord::Schema.define(version: 20170420114823) do

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
    t.string   "name",                          null: false
  end

  add_index "background_jobs", ["completed"], name: "index_background_jobs_on_completed", using: :btree
  add_index "background_jobs", ["legacy_id"], name: "index_background_jobs_on_legacy_id", using: :btree
  add_index "background_jobs", ["name"], name: "index_background_jobs_on_name", using: :btree
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

  create_table "email_templates", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "email_type", null: false
    t.text     "template",   null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "historic_report_cache_entries", force: :cascade do |t|
    t.integer  "historic_report_query_id", null: false
    t.integer  "study_id",                 null: false
    t.datetime "date",                     null: false
  end

  add_index "historic_report_cache_entries", ["date"], name: "index_historic_report_cache_entries_on_date", using: :btree
  add_index "historic_report_cache_entries", ["historic_report_query_id"], name: "index_historic_report_cache_entries_on_historic_report_query_id", using: :btree
  add_index "historic_report_cache_entries", ["study_id"], name: "index_historic_report_cache_entries_on_study_id", using: :btree

  create_table "historic_report_cache_values", force: :cascade do |t|
    t.integer "historic_report_cache_entry_id", null: false
    t.string  "group"
    t.integer "count",                          null: false
    t.integer "delta",                          null: false
  end

  add_index "historic_report_cache_values", ["historic_report_cache_entry_id"], name: "index_historic_report_cache_values_on_entry_id", using: :btree

  create_table "historic_report_queries", force: :cascade do |t|
    t.string   "resource_type"
    t.string   "group_by"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "image_series", force: :cascade do |t|
    t.string   "name"
    t.integer  "visit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "patient_id"
    t.date     "imaging_date"
    t.string   "domino_unid"
    t.integer  "series_number"
    t.integer  "state",              default: 0
    t.string   "comment"
    t.jsonb    "properties",         default: {}, null: false
    t.string   "properties_version"
  end

  add_index "image_series", ["patient_id", "series_number"], name: "index_image_series_on_patient_id_and_series_number", using: :btree
  add_index "image_series", ["patient_id"], name: "index_image_series_on_patient_id", using: :btree
  add_index "image_series", ["series_number"], name: "index_image_series_on_series_number", using: :btree
  add_index "image_series", ["visit_id"], name: "index_image_series_on_visit_id", using: :btree

  create_table "images", force: :cascade do |t|
    t.integer  "image_series_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "images", ["image_series_id"], name: "index_images_on_image_series_id", using: :btree

  create_table "notification_profile_roles", force: :cascade do |t|
    t.integer "notification_profile_id", null: false
    t.integer "role_id",                 null: false
  end

  add_index "notification_profile_roles", ["notification_profile_id", "role_id"], name: "index_notification_profile_roles_join_table_index", unique: true, using: :btree
  add_index "notification_profile_roles", ["role_id"], name: "index_notification_profile_roles_on_role_id", using: :btree

  create_table "notification_profile_users", force: :cascade do |t|
    t.integer "notification_profile_id", null: false
    t.integer "user_id",                 null: false
  end

  add_index "notification_profile_users", ["notification_profile_id", "user_id"], name: "index_notification_profile_users_join_table_index", unique: true, using: :btree
  add_index "notification_profile_users", ["user_id"], name: "index_notification_profile_users_on_user_id", using: :btree

  create_table "notification_profiles", force: :cascade do |t|
    t.string   "title",                                              null: false
    t.text     "description"
    t.string   "notification_type"
    t.string   "triggering_resource",                                null: false
    t.jsonb    "filters",                        default: [],        null: false
    t.boolean  "only_authorized_recipients",     default: true,      null: false
    t.boolean  "is_enabled",                     default: false,     null: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "maximum_email_throttling_delay"
    t.jsonb    "triggering_actions",             default: [],        null: false
    t.integer  "email_template_id",                                  null: false
    t.string   "filter_triggering_user",         default: "exclude", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "notification_profile_id", null: false
    t.integer  "resource_id"
    t.string   "resource_type"
    t.integer  "version_id"
    t.integer  "user_id",                 null: false
    t.datetime "email_sent_at"
    t.datetime "marked_seen_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "triggering_action",       null: false
  end

  add_index "notifications", ["resource_type", "resource_id"], name: "index_notifications_on_resource_type_and_resource_id", using: :btree
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree
  add_index "notifications", ["version_id"], name: "index_notifications_on_version_id", using: :btree

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

  create_table "permissions", force: :cascade do |t|
    t.integer  "role_id",    null: false
    t.string   "activity",   null: false
    t.string   "subject",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "permissions", ["activity"], name: "index_permissions_on_activity", using: :btree
  add_index "permissions", ["role_id"], name: "index_permissions_on_role_id", using: :btree
  add_index "permissions", ["subject"], name: "index_permissions_on_subject", using: :btree

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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",      null: false
  end

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

  create_table "user_roles", force: :cascade do |t|
    t.integer  "user_id",           null: false
    t.integer  "role_id",           null: false
    t.integer  "scope_object_id"
    t.string   "scope_object_type"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "user_roles", ["role_id"], name: "index_user_roles_on_role_id", using: :btree
  add_index "user_roles", ["scope_object_type", "scope_object_id"], name: "index_user_roles_on_scope_object_type_and_scope_object_id", using: :btree
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                   default: "",    null: false
    t.string   "encrypted_password",      default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0
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
    t.integer  "failed_attempts",         default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.boolean  "is_root_user",            default: false, null: false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "email_throttling_delay"
    t.jsonb    "dashboard_configuration"
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
    t.integer  "study_id"
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
    t.integer  "state",                       default: 0
    t.integer  "mqc_state",                   default: 0
    t.jsonb    "assigned_image_series_index", default: {}, null: false
    t.jsonb    "required_series",             default: {}, null: false
    t.jsonb    "mqc_results",                 default: {}, null: false
    t.string   "mqc_comment"
    t.string   "mqc_version"
    t.integer  "repeatable_count",            default: 0,  null: false
  end

  add_index "visits", ["assigned_image_series_index"], name: "index_visits_on_assigned_image_series_index", using: :gin
  add_index "visits", ["mqc_results"], name: "index_visits_on_mqc_results", using: :gin
  add_index "visits", ["mqc_user_id"], name: "index_visits_on_mqc_user_id", using: :btree
  add_index "visits", ["patient_id"], name: "index_visits_on_patient_id", using: :btree
  add_index "visits", ["required_series"], name: "index_visits_on_required_series", using: :gin
  add_index "visits", ["visit_number"], name: "index_visits_on_visit_number", using: :btree

end
