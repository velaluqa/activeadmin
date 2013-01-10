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
  has_many :sessions

  def is_app_admin?
    !(roles.first(:conditions => { :object_type => nil, :object_id => nil, :role => Role::role_sym_to_int(:manage) }).nil?)
  end
end
