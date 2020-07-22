class RequiredSeriesDrop < EricaDrop # :nodoc:
  belongs_to(:visit)
  belongs_to(:image_series)

  desc 'User that performed the tQC.'
  belongs_to(:tqc_user, class_name: 'UserDrop')

  desc 'Name of the required series.', 'String'
  attribute(:name)

  desc 'Results of the completed tQC.', 'Hash<String, String>'
  attribute(:tqc_results)

  desc 'State of the tQC.', 'String'
  attribute(:tqc_state)

  desc 'User comment for that tQC.', 'String'
  attribute(:tqc_comment)

  desc 'Version of the study configuration at time of tQC.', :string
  attribute(:tqc_version)

  desc 'Date of the tQC.', :datetime
  attribute(:tqc_date)

  desc 'List of failed checks.', 'Array<String>'
  def failed_tqc_checks
    (object.tqc_results || {}).map do |name, value|
      name unless value
    end.compact
  end
end
