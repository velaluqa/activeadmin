class AddDashboardConfigurationToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :dashboard_configuration, :jsonb, null: true
  end
end
