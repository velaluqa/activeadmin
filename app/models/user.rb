class User < ActiveRecord::Base
  has_paper_trail

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :name, :password, :password_confirmation, :remember_me
  attr_accessible :public_key, :private_key

  has_many :roles
  has_many :form_answers

  has_and_belongs_to_many :blind_readable_sessions, :class_name => 'Session', :join_table => 'readers_sessions'
  has_and_belongs_to_many :validatable_sessions, :class_name => 'Session', :join_table => 'validators_sessions'

  def is_app_admin?
    !(roles.first(:conditions => { :subject_type => nil, :subject_id => nil, :role => Role::role_sym_to_int(:manage) }).nil?)
  end

  before_create :generate_keys

  def generate_keys
    private_key = OpenSSL::PKey::RSA.generate(4096) #HC
    public_key = private_key.public_key

    write_attribute(:private_key, private_key.to_pem(OpenSSL::Cipher.new('DES-EDE3-CBC'), self.password))
    write_attribute(:public_key, public_key.to_pem)
  end
end
