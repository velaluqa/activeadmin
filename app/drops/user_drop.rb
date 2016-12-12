class UserDrop < EricaDrop # :nodoc:
  has_many(:public_keys)
  has_many(:notifications)

  desc 'Each user is uniquely identified by e-mail.', :string
  attribute(:email)

  desc 'Each user is uniquely identifyable by username.', :string
  attribute(:username)

  desc 'The name of a user (typically the full name)', :string
  attribute(:name)

  desc 'A user can defined how to throttle e-mail notifications.', :integer
  attribute(:email_throttling_delay)

  desc 'A root user has full access to the while system.', :boolean
  attribute(:is_root_user)

  desc 'Count of failed sign in attempts.', :integer
  attribute(:failed_attempts)

  desc 'Date of last password change.', :datetime
  attribute(:password_changed_at)

  desc 'Date the reset password e-mail was sent.', :datetime
  attribute(:reset_password_sent_at)

  desc 'Token to reset the password.', :string
  attribute(:reset_password_token)

  desc 'Date the remembering sign in happended.', :datetime
  attribute(:remember_created_at)

  desc 'New but unconfirmed e-mail address.', :string
  attribute(:unconfirmed_email)

  desc 'Date the e-mail confirmation mail was sent.', :datetime
  attribute(:confirmation_sent_at)

  desc 'Token to confirm the e-mail address.', :string
  attribute(:confirmation_token)

  desc 'Confirmation date of the user account.', :datetime
  attribute(:confirmed_at)

  desc 'Token to unlock the user account.', :string
  attribute(:unlock_token)

  desc 'Date the user was locked.', :datetime
  attribute(:locked_at)

  desc 'Count of sign ins.', :integer
  attribute(:sign_in_count)

  desc 'Date of sign in of the current user session.', :datetime
  attribute(:current_sign_in_at)

  desc 'IP of the current user session.', :string
  attribute(:current_sign_in_ip)

  desc 'Date of the sign in of the last user session.', :datetime
  attribute(:last_sign_in_at)

  desc 'IP of the last user session.', :string
  attribute(:last_sign_in_ip)
end
