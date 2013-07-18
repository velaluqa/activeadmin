class PublicKey < ActiveRecord::Base
  attr_accessible :public_key, :user_id, :active, :deactived_at
  attr_accessible :user
  
  belongs_to :user

  validates :user_id, :public_key, :presence => true
  validates_uniqueness_of :active, :if => :active, :scope => :user_id

  scope :active, where(:active => true)
  scope :deactivated, where(:active => false)

  def deactivate
    self.active = false
    self.deactivated_at = DateTime.now

    self.save
  end

  def openssl_key
    OpenSSL::PKey::RSA.new(self.public_key)
  end
end
