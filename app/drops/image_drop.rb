class ImageDrop < EricaDrop # :nodoc:
  belongs_to(:image_series)
  alias_method :series, :image_series

  desc 'Image Storage Path', :string
  delegate(:image_storage_path, to: :object)

  desc 'Absolute image storage path', :string
  delegate(:absolute_image_storage_path, to: :object)
end
