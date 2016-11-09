class NotificationProfileDrop < Liquid::Rails::Drop # :nodoc:
  attributes(
    :id,
    :title,
    :description,
    :notification_type,
    :is_enabled,
    :triggering_actions,
    :triggering_resource,
    :filters,
    :maximum_email_throttling_delay,
    :only_authorized_recipients,
    :updated_at,
    :created_at
  )

  has_many(:notifications)
end
