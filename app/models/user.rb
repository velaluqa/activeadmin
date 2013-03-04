class User < ActiveRecord::Base
  has_paper_trail

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :name, :password, :password_confirmation, :remember_me
  attr_accessible :public_key, :private_key
  attr_accessible :password_changed_at

  has_many :roles
  has_many :form_answers

  has_many :sessions, :through => :roles, :source => :subject, :source_type => 'Session'

  has_and_belongs_to_many :blind_readable_sessions, :class_name => 'Session', :join_table => 'readers_sessions'
  has_and_belongs_to_many :validatable_sessions, :class_name => 'Session', :join_table => 'validators_sessions'

  before_destroy do
    self.roles.destroy_all
  end

  def email_required?
    false
  end

  def is_app_admin?
    !(roles.first(:conditions => { :subject_type => nil, :subject_id => nil, :role => Role::role_sym_to_int(:manage) }).nil?)
  end

  def test_results_for_session(session)
    test_results = []
    session.form_answers.where(:user_id => self.id).sort(:submitted_at => -1).each do |form_answer|
      test_results << form_answer if(form_answer.case and form_answer.case.flag == :reader_testing)
    end

    return test_results
  end

  before_create :generate_keypair_on_create

  def generate_keypair_on_create
    self.generate_keypair(self.password, false)
  end

  def generate_keypair(private_key_password, save_to_db = true)
    new_private_key = OpenSSL::PKey::RSA.generate(4096) #HC
    new_public_key = new_private_key.public_key

    self.private_key = new_private_key.to_pem(OpenSSL::Cipher.new('DES-EDE3-CBC'), private_key_password)
    self.public_key = new_public_key.to_pem
    self.save! if save_to_db
  end
end
