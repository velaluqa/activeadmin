class AddEmailThrottlingDelayToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email_throttling_delay, :integer
  end
end
