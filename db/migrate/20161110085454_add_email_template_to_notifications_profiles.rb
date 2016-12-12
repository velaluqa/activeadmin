class AddEmailTemplateToNotificationsProfiles < ActiveRecord::Migration #:nodoc:
  def up
    add_column :notification_profiles, :email_template_id, :integer
    if NotificationProfile.count > 0
      dummy_template = EmailTemplate.create(
        email_type: 'NotificationProfile',
        name: 'Dummy Template',
        template: 'If you read this, please notify the administrators that the e-Mail notifications are not set up properly.'
      )
      NotificationProfile.update_all(email_template_id: dummy_template.id)
    end
    change_column :notification_profiles, :email_template_id, :integer, null: false
  end

  def down
    remove_column :notification_profiles, :email_template_id
  end
end
