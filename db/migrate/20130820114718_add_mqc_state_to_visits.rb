class AddMqcStateToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :mqc_state, :integer, default: 0
  end
end
