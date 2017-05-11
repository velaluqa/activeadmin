class CreateReadersSessionsJoinTable < ActiveRecord::Migration
  def change
    create_table :readers_sessions, id: false do |t|
      t.integer :user_id
      t.integer :session_id
    end
    create_table :validators_sessions, id: false do |t|
      t.integer :user_id
      t.integer :session_id
    end

    add_index :readers_sessions, %i[user_id session_id]
    add_index :validators_sessions, %i[user_id session_id]
  end
end
