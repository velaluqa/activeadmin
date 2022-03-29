class NotificationDrop < EricaDrop # :nodoc:
  belongs_to(:user)
  belongs_to(:version)
  belongs_to(:notification_profile)

  desc 'The resource the notification is about.', :polymorphic
  def resource
    item = object.version.item || object.version.reify

    return CommentDrop.new(item) if item.class == ActiveAdmin::Comment

    item
  end

  desc 'Which action triggered this notification (e.g. create, update, destroy)?', :string
  attribute(:triggering_action)

  desc 'Date this notification was marked seen by the user.', :datetime
  attribute(:marked_seen_at)

  desc 'Date this notification was send via e-mail.', :datetime
  attribute(:email_sent_at)
end
