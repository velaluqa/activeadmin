class ConvertVersionDataToJsonb < ActiveRecord::Migration
  def up
    add_column :versions, :new_object, :jsonb
    add_column :versions, :new_object_changes, :jsonb

    progress = ProgressBar.create(
      title: 'Convert Version Data',
      total: Version.count,
      format: '%t |%B| %a / %E (%p%%)'
    )
    ::Version.reset_column_information
    ::Version.find_each do |version|
      if (object = version.object)
        version.update_column :new_object, YAML.safe_load(object)
      end
      if (object_changes = version.object_changes)
        version.update_column :new_object_changes, YAML.safe_load(object_changes)
      end

      progress.increment
    end

    remove_column :versions, :object
    remove_column :versions, :object_changes
    rename_column :versions, :new_object, :object
    rename_column :versions, :new_object_changes, :object_changes
  end

  def down
    add_column :versions, :new_object, :text
    add_column :versions, :new_object_changes, :text

    progress = ProgressBar.create(
      title: 'Revert Version Data',
      total: Version.count,
      format: '%t |%B| %a / %E (%p%%)'
    )
    ::Version.reset_column_information
    ::Version.find_each do |version|
      if (object = version.object)
        version.update_column :new_object, YAML.dump(object)
      end
      if (object_changes = version.object_changes)
        version.update_column :new_object_changes, YAML.dump(object_changes)
      end

      progress.increment
    end

    remove_column :versions, :object
    remove_column :versions, :object_changes
    rename_column :versions, :new_object, :object
    rename_column :versions, :new_object_changes, :object_changes
  end
end
