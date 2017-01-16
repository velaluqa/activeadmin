class AddDashboardConfigurationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :dashboard_configuration, :jsonb, null: true
  end
end
