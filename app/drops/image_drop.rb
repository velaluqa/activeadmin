class ImageDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :created_at,
    :updated_at
  )

  belongs_to(:image_series)
  alias_method :series, :image_series

  delegate(
    :image_storage_path,
    :absolute_image_storage_path,
    to: :object
  )
end
