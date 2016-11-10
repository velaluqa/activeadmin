class BackgroundJobDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :legacy_id,
    :progress,
    :completed,
    :successful,
    :error_message,
    :results,
    :created_at,
    :updated_at,
    :completed_at
  )

  def succeeded?
    successful
  end

  def failed?
    object.failed?
  end

  def finished?
    object.finished?
  end

  belongs_to(:user)
end
