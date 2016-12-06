class NotificationProfileDrop < EricaDrop # :nodoc:
  has_many(:notifications)

  desc 'Title of the notification profile.', :string
  attribute(:title)

  desc 'Description of the notification profile.', :string
  attribute(:description)

  desc 'Type of the notification profile.', :string
  attribute(:notification_type)

  desc 'Whether this notification profile can be triggered or not.', :boolean
  attribute(:is_enabled)

  desc 'Actions that trigger this notification profile.', 'Array<String>'
  attribute(:triggering_actions)

  desc 'Resource that triggers this notification profile.', :string
  attribute(:triggering_resource)

  desc 'Filters that are applied when the notification profile is triggered.', :json
  attribute(:filters)

  desc 'Limitation of the notification delay.', :integer
  attribute(:maximum_email_throttling_delay)

  desc 'Whether only authorized recipients receive notifications for this profile.', :boolean
  attribute(:only_authorized_recipients)
end
