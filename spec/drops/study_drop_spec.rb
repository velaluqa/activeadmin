describe StudyDrop do
  it { is_expected.to have_attribute(:id) }
  it { is_expected.to have_attribute(:state) }
  it { is_expected.to have_attribute(:name) }
  it { is_expected.to have_attribute(:domino_db_url) }
  it { is_expected.to have_attribute(:domino_server_name) }
  it { is_expected.to have_attribute(:notes_links_base_uri) }
  it { is_expected.to have_attribute(:locked_version) }
  it { is_expected.to have_attribute(:created_at) }
  it { is_expected.to have_attribute(:updated_at) }

  it { is_expected.to have_many(:centers) }
  it { is_expected.to have_many(:patients) }
  it { is_expected.to have_many(:visits) }
  it { is_expected.to have_many(:image_series) }
  it { is_expected.to have_many(:images) }
end
