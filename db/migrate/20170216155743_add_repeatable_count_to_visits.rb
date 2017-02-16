class AddRepeatableCountToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :repeatable_count, :integer, default: 0, null: false
  end
end
