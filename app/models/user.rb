require 'email_validator'
# ## Schema Information
#
# Table name: `users`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`authentication_token`**     | `string`           |
# **`confirmation_sent_at`**     | `datetime`         |
# **`confirmation_token`**       | `string`           |
# **`confirmed_at`**             | `datetime`         |
# **`created_at`**               | `datetime`         |
# **`current_sign_in_at`**       | `datetime`         |
# **`current_sign_in_ip`**       | `string`           |
# **`dashboard_configuration`**  | `jsonb`            |
# **`email`**                    | `string`           | `default(""), not null`
# **`email_throttling_delay`**   | `integer`          |
# **`encrypted_password`**       | `string`           | `default(""), not null`
# **`failed_attempts`**          | `integer`          | `default(0)`
# **`id`**                       | `integer`          | `not null, primary key`
# **`is_root_user`**             | `boolean`          | `default(FALSE), not null`
# **`last_sign_in_at`**          | `datetime`         |
# **`last_sign_in_ip`**          | `string`           |
# **`locked_at`**                | `datetime`         |
# **`name`**                     | `string`           |
# **`password_changed_at`**      | `datetime`         |
# **`private_key`**              | `text`             |
# **`public_key`**               | `text`             |
# **`remember_created_at`**      | `datetime`         |
# **`reset_password_sent_at`**   | `datetime`         |
# **`reset_password_token`**     | `string`           |
# **`sign_in_count`**            | `integer`          | `default(0)`
# **`unconfirmed_email`**        | `string`           |
# **`unlock_token`**             | `string`           |
# **`updated_at`**               | `datetime`         |
# **`username`**                 | `string`           |
#
# ### Indexes
#
# * `index_users_on_authentication_token` (_unique_):
#     * **`authentication_token`**
# * `index_users_on_reset_password_token` (_unique_):
#     * **`reset_password_token`**
# * `index_users_on_username` (_unique_):
#     * **`username`**
#
class User < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  devise(
    :database_authenticatable,
    :confirmable,
    :recoverable,
    :rememberable,
    :trackable,
    :lockable,
    :token_authenticatable
  )

  attr_accessible(
    :username,
    :name,
    :email,
    :password,
    :password_confirmation,
    :remember_me,
    :public_key,
    :private_key,
    :password_changed_at
  )

  # Fake attributes for form fields and validation
  attr_accessible :signature_password, :signature_password_confirmation
  attr_accessor :signature_password, :signature_password_confirmation

  validates :username, uniqueness: true, presence: true
  validates :name, uniqueness: true, presence: true
  validates :email, uniqueness: true, presence: true, email: true
  validates :password, confirmation: true, length: { minimum: 6 }, on: :create
  validates :password, confirmation: true, length: { minimum: 6 }, on: :update, allow_blank: true
  validates :signature_password, confirmation: true, length: { minimum: 6 }, on: :create, allow_blank: true

  has_many :user_roles, dependent: :destroy
  accepts_nested_attributes_for :user_roles, allow_destroy: true
  attr_accessible :user_roles_attributes, :email_throttling_delay

  has_many :roles, through: :user_roles
  has_many :permissions, through: :user_roles

  has_many :public_keys

  # A user may be recipient to a multitude of notification profiles.
  has_many :notification_profile_users
  has_many :notification_profiles, through: :notification_profile_users, dependent: :destroy

  # A use might be the sole recipient of many notifications that are
  # for him to decide to be marked as seen.
  has_many :notifications

  before_create :create_keypair

  before_save :ensure_authentication_token
  before_save :reset_authentication_token_on_password_change

  def reset_authentication_token_on_password_change
    reset_authentication_token if encrypted_password_changed?
  end

  def email_required?
    false
  end

  def create_keypair
    return if signature_password.blank?

    generate_keypair(signature_password, false)
  end

  def permission_matrix
    matrix = {}
    Ability::ACTIVITIES.each_pair do |subject, activities|
      if can?(:manage, subject)
        matrix[subject.to_s] = %i[manage]
        next
      end
      granted = activities.map do |activity|
        activity if can?(activity, subject)
      end.compact
      matrix[subject.to_s] = granted unless granted.empty?
    end
    matrix
  end

  scope :searchable, -> { select(<<SELECT.strip_heredoc) }
    NULL::integer AS study_id,
    NULL::varchar AS study_name,
    users.name AS text,
    users.id AS result_id,
    'User'::varchar AS result_type
SELECT

  def self.granted_for(options = {})
    activities = Array(options[:activity]) + Array(options[:activities])
    user = options[:user] || raise("Missing 'user' option")
    return none unless user.can?(activities, self)
    all
  end

  def can?(activity, subject)
    @ability ||= Ability.new(self)
    @ability.can?(activity, subject)
  end

  # HACK: to allow mongoid-history to store the modifier using an ActiveRecord model (this model)
  def self.using_object_ids?
    false
  end

  def self.fields
    [:id]
  end

  def has_valid_password?
    !(password_changed_at.nil? || password_changed_at < Rails.application.config.max_allowed_password_age.ago)
  end

  def has_valid_keypair?
    private_key && public_keys.where(active: true).exists?
  end

  def is_erica_remote_user?
    # TODO: this is filthy, dirty hack territory...
    id >= 1000 && roles.all?(&:erica_remote_role?)
  end

  def generate_keypair(private_key_password, save_to_db = true)
    new_private_key = OpenSSL::PKey::RSA.generate(4096)
    new_public_key = new_private_key.public_key

    self.private_key = new_private_key.to_pem(OpenSSL::Cipher.new('DES-EDE3-CBC'), private_key_password)
    self.public_key = new_public_key.to_pem

    transaction do
      public_keys.active.each(&:deactivate)
      public_keys << PublicKey.new(public_key: public_key, active: true)

      save! if save_to_db
    end
  end

  def active_public_key
    public_keys.active.last
  end

  def sign(data, signature_password)
    private_key = OpenSSL::PKey::RSA.new(self.private_key, signature_password)

    signature = private_key.sign(OpenSSL::Digest::RIPEMD160.new, data)
    pp OpenSSL.errors
    signature
  end

  def dashboard_configuration
    read_attribute(:dashboard_configuration) ||
      ERICA.default_dashboard_configuration
  end

  # Devise does create jobs before commit. So we have to postpone
  # emails until the user is committed to the database.
  after_commit :send_pending_notifications

  protected

  # This method is called by Devise whenever it needs to send a mail.
  # By overriding it we use an ActionJob via Sidekiq.
  def send_devise_notification(notification, *args)
    # If the record is new or changed then delay the
    # delivery until the after_commit callback otherwise
    # send now because after_commit will not be called.
    if new_record? || changed?
      pending_notifications << [notification, args]
    else
      devise_mailer.send(notification, self, *args).deliver_later
    end
  end

  def send_pending_notifications
    pending_notifications.each do |notification, args|
      devise_mailer.send(notification, self, *args).deliver_later
    end
    # Empty the pending notifications array because the
    # after_commit hook can be called multiple times which
    # could cause multiple emails to be sent.
    pending_notifications.clear
  end

  def pending_notifications
    @pending_notifications ||= []
  end

  def self.classify_audit_trail_event(c)
    if c.include?('sign_in_count') &&
       c['sign_in_count'][1] == c['sign_in_count'][0] + 1

      :sign_in
    elsif c.keys == ['remember_created_at']
      :remember_token_updated
    elsif c.include?('encrypted_password') &&
          c.include?('password_changed_at')
      :password_change
    elsif c.include?('failed_attempts')
      if c['failed_attempts'][1] > c['failed_attempts'][0]
        if c.include?('locked_at') && !c['locked_at'][1].blank?
          :user_locked
        else
          :failed_login
        end
      elsif c['failed_attempts'][1] == 0 && c.include?('locked_at') && c['locked_at'][1].blank?
        :user_unlocked
      elsif c['failed_attempts'][1] == 0
        :failed_attempts_reset
      end
    elsif c.include?('private_key') && c.include?('public_key')
      :key_change
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :sign_in then ['Sign-In', :ok]
    when :password_change then ['Password Change', :warning]
    when :failed_login then ['Failed Sign-In attempt', :warning]
    when :user_locked then ['User locked', :error]
    when :user_unlocked then ['User unlocked', :warning]
    when :failed_attempts_reset then ['Failed Sign-In attempts reset', :ok]
    when :remember_token_updated then ['Remember Token Update', :ok]
    when :key_change then ['Keypair Change', :warning]
           end
  end
end
