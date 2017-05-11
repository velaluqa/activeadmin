class AddStateToStudy < ActiveRecord::Migration
  def change
    add_column :studies, :state, :integer, default: 0
  end
end
