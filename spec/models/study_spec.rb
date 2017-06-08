RSpec.describe Study do
  describe 'destroy' do
    let!(:study) { create(:study) }
    let!(:user) { create(:user) }
    let!(:user_role) { create(:user_role, scope_object: study, user: user) }

    it 'destroys related user roles' do
      expect do
        study.destroy
      end.to change(UserRole, :count).by(-1)
    end
  end

  describe 'scope ::searchable' do
    it 'selects search fields' do
      study = create(:study, name: 'FooStudy')
      expect(Study.searchable.as_json)
        .to eq [{
          'id' => nil,
          'study_id' => study.id,
          'study_name' => study.name,
          'text' => 'FooStudy',
          'result_id' => study.id,
          'result_type' => 'Study'
        }]
    end
  end

  describe '::granted_for' do
    let!(:study1) { create(:study) }
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:study2) { create(:study) }
    let!(:center2) { create(:center, study: study2) }
    let!(:patient2) { create(:patient, center: center2) }

    context 'ability read study system-wide' do
      let!(:role) { create(:role, with_permissions: { Study => :read }) }
      let!(:user) { create(:user, with_user_roles: [role]) }

      it 'returns study' do
        expect(Study.granted_for(user: user, activity: :read)).to include(study1)
      end
    end

    context 'ability read study1' do
      let!(:role) { create(:role, with_permissions: { Study => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, study1]]) }
      let(:granted_studies) { Study.granted_for(user: user, activity: :read) }

      it 'returns study' do
        expect(granted_studies).to include(study1)
        expect(granted_studies).not_to include(study2)
      end
    end

    context 'ability read study and center1' do
      let!(:role) { create(:role, with_permissions: { Study => :read, Center => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, center1]]) }
      let(:granted_studies) { Study.granted_for(user: user, activity: :read) }

      it 'returns study' do
        expect(granted_studies).to include(study1)
        expect(granted_studies).not_to include(study2)
      end
    end

    context 'ability read study and patient1' do
      let!(:role) { create(:role, with_permissions: { Study => :read, Patient => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, patient1]]) }
      let(:granted_studies) { Study.granted_for(user: user, activity: :read) }

      it 'returns study' do
        expect(granted_studies).to include(study1)
        expect(granted_studies).not_to include(study2)
      end
    end
  end

  describe 'image storage' do
    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
      create(:study, id: 1)
      expect(File).to exist(ERICA.image_storage_path.join('1'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
      study = create(:study, id: 1)
      expect(File).to exist(ERICA.image_storage_path.join('1'))
      study.id = 2
      study.save
      expect(File).to exist(ERICA.image_storage_path.join('2'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
      study = create(:study, id: 1)
      expect(File).to exist(ERICA.image_storage_path.join('1'))
      study.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1'))
    end
  end

  describe 'scope #by_ids' do
    before :each do
      @study1 = create(:study)
      @study2 = create(:study)
      @study3 = create(:study)
    end

    it 'returns the correct study' do
      expect(Study.by_ids(@study1.id).all)
        .to eq [@study1]
    end
    it 'returns the correct studies' do
      expect(Study.by_ids(@study1.id, @study3.id).all)
        .to eq [@study1, @study3]
      expect(Study.by_ids([@study1.id, @study3.id]).all)
        .to eq [@study1, @study3]
    end
  end

  describe '#visit_templates' do
    let(:study) { create(:study) }
    let(:config_yaml) { <<YAML.strip_heredoc }
      image_series_properties: []
      visit_types:
        baseline:
          description: Some simple visit type
          required_series:
            series1:
              tqc: []
          mqc: []
      visit_templates:
        template:
          visits:
            - number: 1
              type: baseline
YAML

    before(:each) do
      tempfile = Tempfile.new('test.yml')
      tempfile.write(config_yaml)
      tempfile.close
      repo = GitConfigRepository.new
      repo.update_config_file(study.relative_config_file_path, tempfile, nil, "New configuration file for study #{study.id}")
      tempfile.unlink
    end

    it 'returns visit templates of the configuration' do
      expect(study.visit_templates)
        .to eq('template' => { 'visits' => [{ 'number' => 1, 'type' => 'baseline' }] })
    end
  end

  describe '#visit_types' do
    describe 'wrongly configured' do
      let(:study) { create(:study) }
      let(:config_yaml) { <<YAML.strip_heredoc }
        image_series_properties: []
        visit_types:
          pre-intervention
          post-intervention
YAML

      before(:each) do
        tempfile = Tempfile.new('test.yml')
        tempfile.write(config_yaml)
        tempfile.close
        repo = GitConfigRepository.new
        repo.update_config_file(study.relative_config_file_path, tempfile, nil, "New configuration file for study #{study.id}")
        tempfile.unlink
      end

      it 'returns an empty array' do
        expect(study.visit_types).to eq([])
      end
    end
    describe 'configured as mapping' do
    end
  end

  describe '#update_configuration!' do
    let!(:yaml) { <<CONFIG.strip_heredoc }
      image_series_properties: []
      visit_types:
        pre-intervention: {}
        post-intervention: {}
CONFIG
    let!(:yaml2) { <<CONFIG.strip_heredoc }
      image_series_properties: []
      visit_types:
        pre-intervention: {}
        foobar: {}
CONFIG
    let!(:study) { create(:study) }
    let!(:ref) { study.update_configuration!(yaml) }

    it 'saves a new configuration to the study' do
      expect(study.has_configuration?).to be_truthy
      expect(study.current_configuration).to include('image_series_properties' => [])
      expect(study.current_configuration).to include('visit_types' => include('pre-intervention', 'post-intervention'))
    end

    it 'returns the ref of the new configuration' do
      expect(ref).to be_a(String)
    end

    it 'overrides existing configuration' do
      study.update_configuration!(yaml2)
      expect(study.current_configuration).not_to include('visit_types' => include('post-intervention'))
      expect(study.current_configuration).to include('visit_types' => include('foobar'))
    end
  end

  describe '#lock_configuration!' do
    let!(:study) { create(:study) }
    let!(:locked_ref) { study.update_configuration!(<<CONFIG.strip_heredoc) }
      image_series_properties: []
      visit_types:
        pre-intervention: {}
        post-intervention: {}
CONFIG
    before(:each) do
      study.lock_configuration!
      study.reload
    end

    it 'sets the state to `production`' do
      expect(study.state).to eq(:production)
    end

    it 'sets the `locked_version` to current configuration ref' do
      expect(study.locked_version).to eq(locked_ref)
    end
  end

  describe '#unlock_configuration!' do
    let!(:study) { create(:study) }
    let!(:locked_ref) { study.update_configuration!(<<CONFIG.strip_heredoc) }
      image_series_properties: []
      visit_types:
        pre-intervention: {}
        post-intervention: {}
CONFIG
    before(:each) do
      study.lock_configuration!
      study.unlock_configuration!
      study.reload
    end

    it 'sets the state to `building`' do
      expect(study.state).to eq(:building)
    end

    it 'sets the `locked_version` to `nil`' do
      expect(study.locked_version).to be_nil
    end
  end

  describe 'versioning' do
    describe 'create' do
      before(:each) do
        @study = create(:study)
        @study_id = @study.id
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Study').last
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'update' do
      before(:each) do
        @study = create(:study)
        @study_id = @study.id
        @study.name = 'New Name'
        @study.save!
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Study').last
        expect(version.event).to eq 'update'
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'destroy' do
      before(:each) do
        @study = create(:study)
        @study_id = @study.id
        @study.destroy
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Study').last
        expect(version.event).to eq 'destroy'
        expect(version.study_id).to eq @study_id
      end
    end
  end
end
