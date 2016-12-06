class VersionDrop < EricaDrop # :nodoc:
  desc 'The resource that was changed.'
  belongs_to(:item)

  desc 'The event that caused this version object to be created (e.g. create, update, destroy).', :string
  attribute(:event)

  desc 'The object at this version.', :json
  attribute(:object)

  desc 'The changes that changed the previous version to this version.', :json
  attribute(:object_changes)

  desc 'The user who performed this change.', :string
  attribute(:whodunnit)
end
