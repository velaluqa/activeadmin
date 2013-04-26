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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130426111545) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "cases", :force => true do |t|
    t.integer  "position"
    t.integer  "session_id"
    t.integer  "patient_id"
    t.string   "images"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.string   "case_type"
    t.integer  "state",       :default => 0
    t.integer  "flag",        :default => 0
    t.datetime "exported_at"
  end

  add_index "cases", ["patient_id"], :name => "index_views_on_patient_id"
  add_index "cases", ["session_id", "position"], :name => "index_views_on_session_id_and_position", :unique => true
  add_index "cases", ["session_id"], :name => "index_views_on_session_id"

  create_table "centers", :force => true do |t|
    t.string   "name"
    t.integer  "study_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "forms", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "session_id"
    t.integer  "state",          :default => 0
    t.string   "locked_version"
  end

  create_table "image_series", :force => true do |t|
    t.string   "name"
    t.integer  "visit_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "patient_id"
  end

  create_table "images", :force => true do |t|
    t.integer  "image_series_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "patients", :force => true do |t|
    t.string   "subject_id"
    t.string   "images_folder"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "center_id"
  end

  create_table "readers_sessions", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "session_id"
  end

  add_index "readers_sessions", ["user_id", "session_id"], :name => "index_readers_sessions_on_user_id_and_session_id"

  create_table "roles", :force => true do |t|
    t.integer  "subject_id"
    t.string   "subject_type"
    t.integer  "user_id"
    t.integer  "role"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "name"
    t.integer  "study_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "state",          :default => 0
    t.string   "locked_version"
  end

  create_table "studies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "name"
    t.text     "public_key"
    t.text     "private_key"
    t.string   "username"
    t.datetime "password_changed_at"
    t.string   "authentication_token"
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "validators_sessions", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "session_id"
  end

  add_index "validators_sessions", ["user_id", "session_id"], :name => "index_validators_sessions_on_user_id_and_session_id"

  create_table "versions", :force => true do |t|
    t.string   "item_type",      :null => false
    t.integer  "item_id",        :null => false
    t.string   "event",          :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "visits", :force => true do |t|
    t.integer  "visit_number"
    t.string   "visit_type"
    t.integer  "patient_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

end
