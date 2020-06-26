class AddStateToStudy < ActiveRecord::Migration[4.2]
  def change
    add_column :studies, :state, :integer, default: 0
  end
end
