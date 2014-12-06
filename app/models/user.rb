class User < ActiveRecord::Base
  has_paper_trail

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable, :lockable,
         :token_authenticatable, :token_authentication_key => 'authentication_token'

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :name, :password, :password_confirmation, :remember_me
  attr_accessible :public_key, :private_key
  attr_accessible :password_changed_at

  validates :username, :uniqueness => true

  has_many :roles
  has_many :form_answers

  has_many :sessions, :through => :roles, :source => :subject, :source_type => 'Session'
  has_many :assigned_cases, :class_name => 'Case', :foreign_key => 'assigned_reader_id', :inverse_of => :assigned_reader, :dependent => :nullify
  has_many :current_cases, :class_name => 'Case', :foreign_key => 'current_reader_id', :inverse_of => :current_reader, :dependent => :nullify

  has_and_belongs_to_many :blind_readable_sessions, :class_name => 'Session', :join_table => 'readers_sessions'
  has_and_belongs_to_many :validatable_sessions, :class_name => 'Session', :join_table => 'validators_sessions'

  has_many :public_keys

  before_save :ensure_authentication_token
  before_save :reset_authentication_token_on_password_change

  before_destroy do
    self.roles.destroy_all
  end

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

  def is_app_admin?
    has_system_role?(:manage)
  end
  def is_erica_remote_admin?
    has_system_role?(:remote_manage)
  end
  def has_system_role?(role_sym)
    !(roles.first(:conditions => { :subject_type => nil, :subject_id => nil, :role => Role::role_sym_to_int(role_sym) }).nil?)
  end
  def is_erica_remote_user?
    # TODO: this is filthy, dirty hack territory...
    self.id >= 1000 and roles.all? {|role| role.erica_remote_role? }
  end

  def test_results_for_session(session)
    test_results = []
    session.form_answers.where(:user_id => self.id).sort(:submitted_at => 1).each do |form_answer|
      test_results << form_answer if(form_answer.case and form_answer.case.flag == :reader_testing)
    end

    return test_results
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
end
