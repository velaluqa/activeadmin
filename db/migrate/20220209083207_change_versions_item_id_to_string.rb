class ChangeVersionsItemIdToString < ActiveRecord::Migration[5.2]
  def up
    change_column(:versions, :item_id, :string)
  end

  def down
    Version.all.each do |version|
      begin
        Integer(version.item_id)
      rescue => e
        version.item_id = 0
        version.save!
      end
    end
    change_column(:versions, :item_id, :integer, using: 'item_id::integer')
  end
end
