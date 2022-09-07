class CacheDicomwebMetadata < ActiveRecord::Migration[5.2]
  def up
    EnsureDicomwebMetadataCacheWorker.new.perform(
      "image",
      Image.all.pluck(:id)
    )
  end

  def down
  end
end
