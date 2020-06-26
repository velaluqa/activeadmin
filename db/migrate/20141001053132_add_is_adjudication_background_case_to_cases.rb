class AddIsAdjudicationBackgroundCaseToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :is_adjudication_background_case, :boolean, default: false
  end
end
