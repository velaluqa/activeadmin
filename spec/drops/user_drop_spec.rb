describe UserDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:email) }
  it { is_expected.to have_attribute(:username) }
  it { is_expected.to have_attribute(:name) }
  it { is_expected.to have_attribute(:email_throttling_delay) }
  it { is_expected.to have_attribute(:is_root_user) }
  it { is_expected.to have_attribute(:failed_attempts) }
  it { is_expected.to have_attribute(:reset_password_sent_at) }
  it { is_expected.to have_attribute(:reset_password_token) }
  it { is_expected.to have_attribute(:remember_created_at) }
  it { is_expected.to have_attribute(:unconfirmed_email) }
  it { is_expected.to have_attribute(:confirmation_sent_at) }
  it { is_expected.to have_attribute(:confirmation_token) }
  it { is_expected.to have_attribute(:confirmed_at) }
  it { is_expected.to have_attribute(:unlock_token) }
  it { is_expected.to have_attribute(:locked_at) }
  it { is_expected.to have_attribute(:sign_in_count) }
  it { is_expected.to have_attribute(:current_sign_in_at) }
  it { is_expected.to have_attribute(:current_sign_in_ip) }
  it { is_expected.to have_attribute(:last_sign_in_at) }
  it { is_expected.to have_attribute(:last_sign_in_ip) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to have_many(:public_keys) }
  it { is_expected.to have_many(:notifications) }
end
