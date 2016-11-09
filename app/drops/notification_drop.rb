class NotificationDrop < Liquid::Rails::Drop # :nodoc:
  attributes(
    :id,
    :triggering_action,
    :created_at,
    :updated_at,
    :marked_seen_at,
    :email_sent_at
  )

  # belongs_to(:notification_profile)
  belongs_to(:user)
  # belongs_to(:version)
  belongs_to(:resource)
end
