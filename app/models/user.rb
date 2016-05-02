class User < ActiveRecord::Base
  has_paper_trail

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable, :lockable,
         :token_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :name, :password, :password_confirmation, :remember_me
  attr_accessible :public_key, :private_key
  attr_accessible :password_changed_at

  validates :username, :uniqueness => true

  has_many :user_roles, dependent: :destroy
  has_many :permissions, through: :user_roles

  has_many :public_keys

  before_save :ensure_authentication_token
  before_save :reset_authentication_token_on_password_change

  def reset_authentication_token_on_password_change
    self.reset_authentication_token if self.encrypted_password_changed?
  end

  def email_required?
    false
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
    new_private_key = OpenSSL::PKey::RSA.generate(4096) #HC
    new_public_key = new_private_key.public_key

    self.private_key = new_private_key.to_pem(OpenSSL::Cipher.new('DES-EDE3-CBC'), private_key_password)
    self.public_key = new_public_key.to_pem
    
    if(save_to_db)
      transaction do
        self.public_keys.active.last.deactivate unless self.public_keys.active.empty?
        PublicKey.create(:user => self, :public_key => self.public_key, :active => true)

        self.save!
      end
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

  # fake attributes to enable us to use them in the create user form
  attr_accessible :signature_password, :signature_password_confirmation
  def signature_password
    nil
  end
  def signature_password=(p)
  end
  def signature_password_confirmation
    nil
  end
  def signature_password_confirmation=(p)
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
