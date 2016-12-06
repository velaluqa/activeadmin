class VisitDrop < EricaDrop # :nodoc:
  belongs_to(:patient)
  has_many(:image_series)

  desc 'The user who performed the medical QC.'
  belongs_to(:mqc_user, class_name: 'UserDrop')

  desc 'State of the visit.', :integer
  attributes(:state)

  desc 'Type of the visit.', :string
  attributes(:visit_type)

  desc 'Number of the visit.', :string
  attributes(:visit_number)

  desc 'Descriptions of the visit.', :string
  attributes(:description)

  desc 'Required Series information.', :json
  attributes(:required_series)

  desc 'Index of the assigned image series.', :json
  attributes(:assigned_image_series_index)

  desc 'Comment for the visit.', :string
  attributes(:mqc_comment)

  desc 'Date the medical QC was performed.', :datetime
  attributes(:mqc_date)

  desc 'Results of the medical QC.', :json
  attributes(:mqc_results)

  desc 'State of the medical QC.', :integer
  attributes(:mqc_state)

  desc 'ID of the user who performed medial QC.', :integer
  attributes(:mqc_user_id)

  desc 'Version at which the medical QC was performed.', :string
  attributes(:mqc_version)

  desc 'UNID for the domino sync.', :string
  attributes(:domino_unid)
end
