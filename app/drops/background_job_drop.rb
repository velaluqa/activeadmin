class BackgroundJobDrop < EricaDrop # :nodoc:
  desc 'Normal users should only see their own background jobs.', 'Array<UserDrop>'
  belongs_to(:user)

  desc 'The progress from 0.0 to 100.0.', :float
  attribute(:progress)

  desc 'A message as String if there was an error.', :string
  attribute(:error_message)

  desc 'The results of the background job as JSON.', :json
  attribute(:results)

  desc 'Completion date of the job', :datetime
  attribute(:completed_at)

  desc 'Returns `true` if the background job succeeded.', :boolean
  def succeeded?
    object.successful
  end

  desc 'Returns `true` if the background job failed.', :boolean
  def failed?
    object.failed?
  end

  desc 'Returns `true` if the background job finished. Regardless of the outcome.', :boolean
  def finished?
    object.finished?
  end
end
