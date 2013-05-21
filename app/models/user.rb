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

  has_and_belongs_to_many :blind_readable_sessions, :class_name => 'Session', :join_table => 'readers_sessions'
  has_and_belongs_to_many :validatable_sessions, :class_name => 'Session', :join_table => 'validators_sessions'

  has_many :image_series, :dependent => :nullify, :foreign_key => 'tqc_user_id'

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

  def is_app_admin?
    has_system_role?(:manage)
  end
  def has_system_role?(role_sym)
    !(roles.first(:conditions => { :subject_type => nil, :subject_id => nil, :role => Role::role_sym_to_int(role_sym) }).nil?)
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
    self.save! if save_to_db
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
