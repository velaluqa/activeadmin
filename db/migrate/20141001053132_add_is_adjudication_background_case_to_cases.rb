class AddIsAdjudicationBackgroundCaseToCases < ActiveRecord::Migration
  def change
    add_column :cases, :is_adjudication_background_case, :boolean, default: false
  end
end
