class VersionDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :event,
    :object,
    :object_changes,
    :whodunnit,
    :created_at
  )

  belongs_to(:item)
end
