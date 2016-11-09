describe UserDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:email) }
  it { should have_attribute(:username) }
  it { should have_attribute(:name) }
  it { should have_attribute(:email_throttling_delay) }
  it { should have_attribute(:is_root_user) }
  it { should have_attribute(:authentication_token) }
  it { should have_attribute(:failed_attempts) }
  it { should have_attribute(:public_key) }
  it { should have_attribute(:private_key) }
  it { should have_attribute(:encrypted_password) }
  it { should have_attribute(:password_changed_at) }
  it { should have_attribute(:reset_password_sent_at) }
  it { should have_attribute(:reset_password_token) }
  it { should have_attribute(:remember_created_at) }
  it { should have_attribute(:unconfirmed_email) }
  it { should have_attribute(:confirmation_sent_at) }
  it { should have_attribute(:confirmation_token) }
  it { should have_attribute(:confirmed_at) }
  it { should have_attribute(:unlock_token) }
  it { should have_attribute(:locked_at) }
  it { should have_attribute(:sign_in_count) }
  it { should have_attribute(:current_sign_in_at) }
  it { should have_attribute(:current_sign_in_ip) }
  it { should have_attribute(:last_sign_in_at) }
  it { should have_attribute(:last_sign_in_ip) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should have_many(:public_keys) }
  it { should have_many(:notifications) }
end
