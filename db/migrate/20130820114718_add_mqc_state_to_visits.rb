class AddMqcStateToVisits < ActiveRecord::Migration[4.2]
  def change
    add_column :visits, :mqc_state, :integer, default: 0
  end
end
