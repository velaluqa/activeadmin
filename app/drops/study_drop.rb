class StudyDrop < EricaDrop # :nodoc:
  has_many(:centers)
  has_many(:patients)
  has_many(:visits)
  has_many(:image_series)
  has_many(:images)

  desc 'The state of the study.', :string
  attribute(:state)

  desc 'The name of the study.', :string
  attribute(:name)

  desc 'The URL of the domino database to sync to.', :string
  attribute(:domino_db_url)

  desc 'The name of the domino server.', :string
  attribute(:domino_server_name)

  desc 'The base URL of lotus links.', :string
  attribute(:notes_links_base_uri)

  desc 'The version at which this study is locked.', :string
  attribute(:locked_version)
end
