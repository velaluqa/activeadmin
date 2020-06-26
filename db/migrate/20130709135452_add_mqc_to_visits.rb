class AddMqcToVisits < ActiveRecord::Migration[4.2]
  def change
    add_column :visits, :mqc_date, :datetime
    add_column :visits, :mqc_user_id, :integer
    add_column :visits, :state, :integer, default: 0
  end
end
