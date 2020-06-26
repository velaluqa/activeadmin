class AddDescriptionToVisit < ActiveRecord::Migration[4.2]
  def change
    add_column :visits, :description, :string
  end
end
