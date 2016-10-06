class AddConfirmableUserColumns < ActiveRecord::Migration
  def change
    add_column :users, :confirmation_token, :string, null: true
    add_column :users, :confirmed_at, :datetime, null: true
    add_column :users, :confirmation_sent_at, :datetime, null: true
    add_column :users, :unconfirmed_email, :string, null: true
  end
end
