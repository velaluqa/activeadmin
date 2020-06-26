class RenameOldVisitRequiredSeries < ActiveRecord::Migration[4.2]
  def change
    rename_column :visits, :required_series, :old_required_series
    rename_column :visits, :assigned_image_series_index, :old_assigned_image_series_index
  end
end
