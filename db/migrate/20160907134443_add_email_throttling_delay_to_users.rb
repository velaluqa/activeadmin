class AddEmailThrottlingDelayToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email_throttling_delay, :integer
  end
end
