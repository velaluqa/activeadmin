class StudyDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :state,
    :name,
    :domino_db_url,
    :domino_server_name,
    :notes_links_base_uri,
    :locked_version,
    :created_at,
    :updated_at
  )

  has_many(:centers)
  has_many(:patients)
  has_many(:visits)
  has_many(:image_series)
  has_many(:images)
end
