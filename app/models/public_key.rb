# ## Schema Information
#
# Table name: `public_keys`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`active`**          | `boolean`          | `not null`
# **`created_at`**      | `datetime`         |
# **`deactivated_at`**  | `datetime`         |
# **`id`**              | `integer`          | `not null, primary key`
# **`public_key`**      | `text`             | `not null`
# **`updated_at`**      | `datetime`         |
# **`user_id`**         | `integer`          | `not null`
#
# ### Indexes
#
# * `index_public_keys_on_active`:
#     * **`active`**
# * `index_public_keys_on_user_id`:
#     * **`user_id`**
#
class PublicKey < ActiveRecord::Base
  attr_accessible :public_key, :user_id, :active, :deactivated_at
  attr_accessible :user

  belongs_to :user

  validates :user_id, :public_key, :presence => true
  validates_uniqueness_of :active, :if => :active, :scope => :user_id

  scope :active, -> { where(:active => true) }
  scope :deactivated, -> { where(:active => false) }

  def active?
    self.active
  end

  def deactivate
    self.active = false
    self.deactivated_at = DateTime.now

    self.save
  end

  def openssl_key
    OpenSSL::PKey::RSA.new(self.public_key)
  end
end
