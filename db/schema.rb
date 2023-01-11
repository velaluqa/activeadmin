# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_12_14_132751) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_enum :background_jobs_state_type, [
    "scheduled",
    "running",
    "cancelling",
    "successful",
    "failed",
    "cancelled",
  ], force: :cascade

  create_enum :configuration_schema_specs, [
    "formio_v1",
  ], force: :cascade

  create_table "active_admin_comments", id: :serial, force: :cascade do |t|
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "author_type"
    t.integer "author_id"
    t.text "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "namespace"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "background_jobs", id: :serial, force: :cascade do |t|
    t.string "legacy_id"
    t.string "name", null: false
    t.integer "user_id"
    t.boolean "completed", default: false, null: false
    t.float "progress", default: 0.0, null: false
    t.datetime "completed_at"
    t.boolean "successful"
    t.text "error_message"
    t.jsonb "results", default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.enum "state", default: "scheduled", null: false, enum_type: "background_jobs_state_type"
    t.index ["completed"], name: "index_background_jobs_on_completed"
    t.index ["legacy_id"], name: "index_background_jobs_on_legacy_id"
    t.index ["results"], name: "index_background_jobs_on_results", using: :gin
    t.index ["user_id"], name: "index_background_jobs_on_user_id"
  end

  create_table "cases", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.integer "session_id"
    t.integer "patient_id"
    t.string "images"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "case_type"
    t.integer "state", default: 0
    t.integer "flag", default: 0
    t.datetime "exported_at"
    t.boolean "no_export", default: false
    t.string "comment"
    t.integer "assigned_reader_id"
    t.integer "current_reader_id"
    t.boolean "is_adjudication_background_case", default: false
    t.index ["assigned_reader_id"], name: "index_cases_on_assigned_reader_id"
    t.index ["current_reader_id"], name: "index_cases_on_current_reader_id"
    t.index ["patient_id"], name: "index_cases_on_patient_id"
    t.index ["position"], name: "index_cases_on_position"
    t.index ["session_id", "position"], name: "index_cases_on_session_id_and_position", unique: true
    t.index ["session_id"], name: "index_cases_on_session_id"
  end

  create_table "centers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "code"
    t.string "domino_unid"
    t.index ["study_id", "code"], name: "index_centers_on_study_id_and_code", unique: true
    t.index ["study_id"], name: "index_centers_on_study_id"
  end

  create_table "configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "previous_configuration_id"
    t.text "payload", null: false
    t.string "configurable_type", null: false
    t.uuid "configurable_id", null: false
    t.enum "schema_spec", null: false, comment: "Specify the configuration schema for the given `configuration_type`.\n", enum_type: "configuration_schema_specs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["configurable_id"], name: "index_configurations_on_configurable_id"
    t.index ["previous_configuration_id"], name: "index_configurations_on_previous_configuration_id"
  end

  create_table "email_templates", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "email_type", null: false
    t.text "template", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "form_answer_resources", force: :cascade do |t|
    t.uuid "form_answer_id", null: false
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.index ["form_answer_id", "resource_id", "resource_type"], name: "form_answer_resources_primary_key_index", unique: true
    t.index ["form_answer_id"], name: "index_form_answer_resources_on_form_answer_id"
    t.index ["resource_id", "resource_type"], name: "form_answer_resources_resource_index"
  end

  create_table "form_answers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "form_definition_id", null: false
    t.uuid "configuration_id", null: false
    t.text "signing_reason"
    t.bigint "public_key_id", comment: "Public key used for signatures.\n"
    t.jsonb "answers", comment: "Answers to the form.\n"
    t.string "answers_signature", comment: "RSA Signature via private part of `public_key`.\n"
    t.jsonb "annotated_images", comment: "List of annotated images including their checksum.\n"
    t.string "annotated_images_signature", comment: "RSA Signature via private part of `public_key`.\n"
    t.boolean "is_test_data", default: false, null: false
    t.boolean "is_obsolete", default: false, null: false
    t.datetime "signed_at"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "study_id"
    t.integer "form_session_id"
    t.integer "form_display_type_id"
    t.datetime "published_at"
    t.integer "sequence_number", default: 0, null: false
    t.integer "blocking_user_id"
    t.datetime "blocked_at"
    t.index ["configuration_id"], name: "index_form_answers_on_configuration_id"
    t.index ["form_definition_id"], name: "index_form_answers_on_form_definition_id"
    t.index ["public_key_id"], name: "index_form_answers_on_public_key_id"
  end

  create_table "form_definitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.uuid "locked_configuration_id"
    t.datetime "locked_at"
    t.uuid "current_configuration_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "form_sessions", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_form_sessions_on_name"
  end

  create_table "forms", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "session_id"
    t.integer "state", default: 0
    t.string "locked_version"
    t.index ["session_id"], name: "index_forms_on_session_id"
  end

  create_table "historic_report_cache_entries", id: :serial, force: :cascade do |t|
    t.integer "historic_report_query_id", null: false
    t.integer "study_id", null: false
    t.datetime "date", null: false
    t.integer "version_id"
    t.index ["date"], name: "index_historic_report_cache_entries_on_date"
    t.index ["historic_report_query_id"], name: "index_historic_report_cache_entries_on_historic_report_query_id"
    t.index ["study_id"], name: "index_historic_report_cache_entries_on_study_id"
  end

  create_table "historic_report_cache_values", id: :serial, force: :cascade do |t|
    t.integer "historic_report_cache_entry_id", null: false
    t.string "group"
    t.integer "count", null: false
    t.integer "delta", null: false
    t.index ["historic_report_cache_entry_id"], name: "index_historic_report_cache_values_on_entry_id"
  end

  create_table "historic_report_queries", id: :serial, force: :cascade do |t|
    t.string "resource_type"
    t.string "group_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "image_series", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "visit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "patient_id"
    t.date "imaging_date"
    t.string "domino_unid"
    t.integer "series_number"
    t.integer "state", default: 0
    t.string "comment"
    t.jsonb "properties", default: {}, null: false
    t.string "properties_version"
    t.index ["patient_id", "series_number"], name: "index_image_series_on_patient_id_and_series_number"
    t.index ["patient_id"], name: "index_image_series_on_patient_id"
    t.index ["series_number"], name: "index_image_series_on_series_number"
    t.index ["visit_id"], name: "index_image_series_on_visit_id"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.integer "image_series_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "mimetype"
    t.string "sha256sum"
    t.index ["image_series_id"], name: "index_images_on_image_series_id"
  end

  create_table "notification_profile_roles", id: :serial, force: :cascade do |t|
    t.integer "notification_profile_id", null: false
    t.integer "role_id", null: false
    t.index ["notification_profile_id", "role_id"], name: "index_notification_profile_roles_join_table_index", unique: true
    t.index ["role_id"], name: "index_notification_profile_roles_on_role_id"
  end

  create_table "notification_profile_users", id: :serial, force: :cascade do |t|
    t.integer "notification_profile_id", null: false
    t.integer "user_id", null: false
    t.index ["notification_profile_id", "user_id"], name: "index_notification_profile_users_join_table_index", unique: true
    t.index ["user_id"], name: "index_notification_profile_users_on_user_id"
  end

  create_table "notification_profiles", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "notification_type"
    t.string "triggering_resource", null: false
    t.jsonb "filters", default: [], null: false
    t.boolean "only_authorized_recipients", default: true, null: false
    t.boolean "is_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "maximum_email_throttling_delay"
    t.jsonb "triggering_actions", default: [], null: false
    t.integer "email_template_id", null: false
    t.string "filter_triggering_user", default: "exclude", null: false
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "notification_profile_id", null: false
    t.string "resource_type"
    t.integer "resource_id"
    t.integer "version_id"
    t.integer "user_id", null: false
    t.datetime "email_sent_at"
    t.datetime "marked_seen_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "triggering_action", null: false
    t.index ["resource_type", "resource_id"], name: "index_notifications_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
    t.index ["version_id"], name: "index_notifications_on_version_id"
  end

  create_table "patients", id: :serial, force: :cascade do |t|
    t.string "subject_id"
    t.string "images_folder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "center_id"
    t.string "domino_unid"
    t.jsonb "data", default: {}, null: false
    t.jsonb "export_history", default: [], null: false
    t.index ["center_id"], name: "index_patients_on_center_id"
  end

  create_table "permissions", id: :serial, force: :cascade do |t|
    t.integer "role_id", null: false
    t.string "activity", null: false
    t.string "subject", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity"], name: "index_permissions_on_activity"
    t.index ["role_id"], name: "index_permissions_on_role_id"
    t.index ["subject"], name: "index_permissions_on_subject"
  end

  create_table "public_keys", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "public_key", null: false
    t.boolean "active", null: false
    t.datetime "deactivated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["active"], name: "index_public_keys_on_active"
    t.index ["user_id"], name: "index_public_keys_on_user_id"
  end

  create_table "readers_sessions", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "session_id"
    t.index ["user_id", "session_id"], name: "index_readers_sessions_on_user_id_and_session_id"
  end

  create_table "required_series", id: :serial, force: :cascade do |t|
    t.integer "visit_id", null: false
    t.string "name", null: false
    t.integer "image_series_id"
    t.integer "tqc_state"
    t.datetime "tqc_date"
    t.string "tqc_version"
    t.jsonb "tqc_results"
    t.integer "tqc_user_id"
    t.text "tqc_comment"
    t.string "domino_unid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_series_id"], name: "index_required_series_on_image_series_id"
    t.index ["visit_id", "name"], name: "index_required_series_on_visit_id_and_name", unique: true
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title", null: false
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "state", default: 0
    t.string "locked_version"
    t.index ["study_id"], name: "index_sessions_on_study_id"
  end

  create_table "studies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "locked_version"
    t.string "domino_db_url"
    t.string "notes_links_base_uri"
    t.string "domino_server_name"
    t.integer "state", default: 0
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.string "scope_object_type"
    t.integer "scope_object_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["scope_object_type", "scope_object_id"], name: "index_user_roles_on_scope_object_type_and_scope_object_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.text "public_key"
    t.text "private_key"
    t.string "username"
    t.datetime "password_changed_at"
    t.string "authentication_token"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "is_root_user", default: false, null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "email_throttling_delay"
    t.jsonb "dashboard_configuration"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "validators_sessions", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "session_id"
    t.index ["user_id", "session_id"], name: "index_validators_sessions_on_user_id_and_session_id"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.string "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.datetime "created_at"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.integer "study_id"
    t.boolean "migrated_required_series", default: false, null: false
    t.uuid "form_definition_id"
    t.uuid "form_answer_id"
    t.uuid "configuration_id"
    t.string "comment"
    t.string "item_name"
    t.integer "background_job_id"
    t.index "((object ->> 'name'::text))", name: "idx_on_versions_rs_changes1"
    t.index "((object ->> 'visit_id'::text))", name: "idx_on_versions_rs_changes2"
    t.index "((object_changes #>> '{name,1}'::text[]))", name: "idx_on_versions_rs_changes3"
    t.index "((object_changes #>> '{visit_id,1}'::text[]))", name: "idx_on_versions_rs_changes4"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "visits", id: :serial, force: :cascade do |t|
    t.integer "visit_number"
    t.string "visit_type"
    t.integer "patient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "domino_unid"
    t.string "description"
    t.datetime "mqc_date"
    t.integer "mqc_user_id"
    t.integer "state", default: 0
    t.integer "mqc_state", default: 0
    t.jsonb "old_assigned_image_series_index", default: {}, null: false
    t.jsonb "old_required_series", default: {}, null: false
    t.jsonb "mqc_results", default: {}, null: false
    t.string "mqc_comment"
    t.string "mqc_version"
    t.integer "repeatable_count", default: 0, null: false
    t.index ["mqc_results"], name: "index_visits_on_mqc_results", using: :gin
    t.index ["mqc_user_id"], name: "index_visits_on_mqc_user_id"
    t.index ["old_assigned_image_series_index"], name: "index_visits_on_old_assigned_image_series_index", using: :gin
    t.index ["old_required_series"], name: "index_visits_on_old_required_series", using: :gin
    t.index ["patient_id"], name: "index_visits_on_patient_id"
    t.index ["visit_number"], name: "index_visits_on_visit_number"
  end

end
