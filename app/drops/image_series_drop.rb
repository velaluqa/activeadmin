class ImageSeriesDrop < EricaDrop # :nodoc:
  belongs_to(:visit)
  belongs_to(:patient)
  has_many(:images)

  desc 'ID of the associated visit.', :integer
  attribute(:visit_id)

  desc 'ID of the associated patient.', :integer
  attribute(:patient_id)

  desc 'State of the image series.', :string
  attribute(:state)

  desc 'Number of the image series.', :string
  attribute(:series_number)

  desc 'Name of the image series.', :string
  attribute(:name)

  desc 'Internal image series comment.', :string
  attribute(:comment)

  desc 'Date this imageseries was imaged.', :datetime
  attribute(:imaging_date)

  desc 'Properties object.', :json
  attribute(:properties)

  desc 'Properties version.', :string
  attribute(:properties_version)

  desc 'UNID for domino sync.', :string
  attribute(:domino_unid)
end
