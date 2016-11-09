describe StudyDrop do
  it { should have_attribute(:id) }
  it { should have_attribute(:state) }
  it { should have_attribute(:name) }
  it { should have_attribute(:domino_db_url) }
  it { should have_attribute(:domino_server_name) }
  it { should have_attribute(:notes_links_base_uri) }
  it { should have_attribute(:locked_version) }
  it { should have_attribute(:created_at) }
  it { should have_attribute(:updated_at) }

  it { should have_many(:centers) }
  it { should have_many(:patients) }
  it { should have_many(:visits) }
  it { should have_many(:image_series) }
  it { should have_many(:images) }
end
