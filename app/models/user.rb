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

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :confirmable,
         :recoverable, :rememberable, :trackable, :lockable,
         :token_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :name, :email, :password, :password_confirmation
  attr_accessible :remember_me, :public_key, :private_key
  attr_accessible :password_changed_at

  # Fake attributes for form fields and validation
  attr_accessible :signature_password, :signature_password_confirmation
  attr_accessor :signature_password, :signature_password_confirmation
  
  validates :username, :uniqueness => true, :presence => true
  validates :name, :uniqueness => true, :presence => true
  validates :email, :uniqueness => true, :presence => true, :email => true
  validates :password, :confirmation => true, :length => { :minimum => 6 }, on: :create
  validates :password, :confirmation => true, :length => { :minimum => 6 }, on: :update, allow_blank: true
  validates :signature_password, :confirmation => true, :length => { :minimum => 6 }, on: :create, allow_blank: true

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
    self.reset_authentication_token if self.encrypted_password_changed?
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
        matrix[subject.to_s] = %i(manage)
        next
      end
      granted = activities.map do |activity|
        activity if can?(activity, subject)
      end.compact
      matrix[subject.to_s] = granted unless granted.empty?
    end
    matrix
  end

  def can?(activity, subject)
    @ability ||= Ability.new(self)
    @ability.can?(activity, subject)
  end
  
  # hack to allow mongoid-history to store the modifier using an ActiveRecord model (this model)
  def self.using_object_ids?
    false
  end
  def self.fields
    [:id]
  end

  def is_erica_remote_user?
    # TODO: this is filthy, dirty hack territory...
    self.id >= 1000 and roles.all? {|role| role.erica_remote_role? }
  end

  def generate_keypair(private_key_password, save_to_db = true)
    new_private_key = OpenSSL::PKey::RSA.generate(4096)
    new_public_key = new_private_key.public_key

    self.private_key = new_private_key.to_pem(OpenSSL::Cipher.new('DES-EDE3-CBC'), private_key_password)
    self.public_key = new_public_key.to_pem

    transaction do
      public_keys.active.each(&:deactivate)
      public_keys << PublicKey.new(:public_key => public_key, :active => true)

      save! if save_to_db
    end
  end
  def active_public_key
    self.public_keys.active.last
  end

  def sign(data, signature_password)
    private_key = OpenSSL::PKey::RSA.new(self.private_key, signature_password)

    signature = private_key.sign(OpenSSL::Digest::RIPEMD160.new, data)
    pp OpenSSL.errors
    return signature
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
    if(c.include?('sign_in_count') and
       c['sign_in_count'][1] == c['sign_in_count'][0]+1
      )
      return :sign_in
    elsif(c.keys == ['remember_created_at'])
      return :remember_token_updated
    elsif(c.include?('encrypted_password') and
          c.include?('password_changed_at'))
      return :password_change
    elsif(c.include?('failed_attempts'))
      if(c['failed_attempts'][1] > c['failed_attempts'][0])
        if(c.include?('locked_at') and not c['locked_at'][1].blank?)
          return :user_locked
        else
          return :failed_login
        end
      elsif(c['failed_attempts'][1] == 0 and c.include?('locked_at') and c['locked_at'][1].blank?)
        return :user_unlocked
      elsif(c['failed_attempts'][1] == 0)
        return :failed_attempts_reset
      end
    elsif(c.include?('private_key') and c.include?('public_key'))
      return :key_change
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
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
