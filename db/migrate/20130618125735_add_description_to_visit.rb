class AddDescriptionToVisit < ActiveRecord::Migration
  def change
    add_column :visits, :description, :string
  end
end
