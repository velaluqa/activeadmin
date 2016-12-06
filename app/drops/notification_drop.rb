class NotificationDrop < EricaDrop # :nodoc:
  belongs_to(:user)

  desc 'The resource the notification is about.', :polymorphic
  belongs_to(:resource)

  desc 'Which action triggered this notification (e.g. create, update, destroy)?', :string
  attribute(:triggering_action)

  desc 'Date this notification was marked seen by the user.', :datetime
  attribute(:marked_seen_at)

  desc 'Date this notification was send via e-mail.', :datetime
  attribute(:email_sent_at)
end
