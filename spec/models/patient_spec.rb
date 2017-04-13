RSpec.describe Patient do
  describe 'destroy' do
    let!(:patient) { create(:patient) }
    let!(:user) { create(:user) }
    let!(:user_role) { create(:user_role, scope_object: patient, user: user) }

    it 'destroys related user roles' do
      expect {
        patient.destroy
      }.to change(UserRole, :count).by(-1)
    end
  end

  describe 'scope ::searchable' do
    it 'selects search fields' do
      center = create(:center, code: 'Foo')
      patient = create(:patient, subject_id: 'Bar', center: center)
      expect(Patient.searchable.as_json)
        .to eq [{
                  'id' => nil,
                  'study_id' => patient.center.study_id,
                  'study_name' => patient.center.study.name,
                  'text' => 'FooBar',
                  'result_id' => patient.id,
                  'result_type' => 'Patient'
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

    context 'ability read Patient system-wide' do
      let!(:role) { create(:role, with_permissions: { Patient => :read }) }
      let!(:user) { create(:user, with_user_roles: [role]) }
      let(:granted_patients) { Patient.granted_for(user: user, activity: :read) }

      it 'returns all centers' do
        expect(granted_patients).to include(patient1)
        expect(granted_patients).to include(patient2)
      end
    end

    context 'ability read patient1' do
      let!(:role) { create(:role, with_permissions: { Patient => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, patient1]]) }
      let(:granted_patients) { Patient.granted_for(user: user, activity: :read) }

      it 'returns only patient1' do
        expect(granted_patients).to include(patient1)
        expect(granted_patients).not_to include(patient2)
      end
    end

    context 'ability read Patient and study1' do
      let!(:role) { create(:role, with_permissions: { Study => :read, Patient => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, study1]]) }
      let(:granted_patients) { Patient.granted_for(user: user, activity: :read) }

      it 'returns only patient1' do
        expect(granted_patients).to include(patient1)
        expect(granted_patients).not_to include(patient2)
      end
    end

    context 'ability read Patient and center1' do
      let!(:role) { create(:role, with_permissions: { Center => :read, Patient => :read }) }
      let!(:user) { create(:user, with_user_roles: [[role, center1]]) }
      let(:granted_patients) { Patient.granted_for(user: user, activity: :read) }

      it 'returns only patient1' do
        expect(granted_patients).to include(patient1)
        expect(granted_patients).not_to include(patient2)
      end
    end
  end

  describe 'image storage' do
    before(:each) do
      @study = create(:study, id: 1)
      @center = create(:center, id: 1, study: @study)
      @center2 = create(:center, id: 2, study: @study)
      expect(File).to exist(ERICA.image_storage_path.join('1/1'))
      expect(File).to exist(ERICA.image_storage_path.join('1/2'))
    end

    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
      create(:patient, id: 1, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
      center = create(:patient, id: 1, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1'))
      center.center_id = 2
      center.save
      expect(File).to exist(ERICA.image_storage_path.join('1/2/1'))
      expect(File).to exist(ERICA.image_storage_path.join('1/2/1/__unassigned'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
      patient = create(:patient, id: 1, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1'))
      patient.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1'))
    end
  end

  describe 'scope #by_study_ids' do
    before :each do
      @study1 = create(:study)
      @center11 = create(:center, study: @study1)
      @patient111 = create(:patient, center: @center11)
      @patient112 = create(:patient, center: @center11)
      @center12 = create(:center, study: @study1)
      @patient121 = create(:patient, center: @center12)
      @patient122 = create(:patient, center: @center12)
      @study2 = create(:study)
      @center21 = create(:center, study: @study2)
      @patient211 = create(:patient, center: @center21)
      @patient212 = create(:patient, center: @center21)
      @center22 = create(:center, study: @study2)
      @patient221 = create(:patient, center: @center22)
      @patient222 = create(:patient, center: @center22)
      @study3 = create(:study)
      @center31 = create(:center, study: @study3)
      @patient311 = create(:patient, center: @center31)
      @patient312 = create(:patient, center: @center31)
      @center32 = create(:center, study: @study3)
      @patient321 = create(:patient, center: @center32)
      @patient322 = create(:patient, center: @center32)
    end

    it 'returns the matched patients for a single study' do
      expect(Patient.by_study_ids(@study1.id))
        .to match_array [
          @patient111, @patient112, @patient121, @patient122
        ]
    end

    it 'returns the matched patients for a single study' do
      expect(Patient.by_study_ids(@study1.id, @study3.id))
        .to match_array [
          @patient111, @patient112, @patient121, @patient122,
          @patient311, @patient312, @patient321, @patient322
        ]
      expect(Patient.by_study_ids([@study1.id, @study3.id]))
        .to match_array [
          @patient111, @patient112, @patient121, @patient122,
          @patient311, @patient312, @patient321, @patient322
        ]
    end
  end

  describe '#create' do
    describe 'for study with visit template' do
      let!(:study) { create(:study) }
      let!(:center) { create(:center, study: study) }
      let!(:config_yaml) { <<YAML }
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
        description: 'Some preset for a visit'
YAML

      before(:each) do
        # TODO: #2644 - Refactor configuring Study
        tempfile = Tempfile.new('test.yml')
        tempfile.write(config_yaml)
        tempfile.close
        repo = GitConfigRepository.new
        repo.update_config_file(study.relative_config_file_path, tempfile, nil, "New configuration file for study #{study.id}")
        tempfile.unlink
      end

      it 'creates visits from template' do
        patient = Patient.new(
          center: center,
          subject_id: '1234'
        )
        patient.visit_template = 'template'
        patient.save!
        expect(patient.visits.count).to eq 1
      end
    end

    describe 'for study with enforced visit template' do
      let!(:study) { create(:study) }
      let!(:center) { create(:center, study: study) }
      let!(:config_yaml) { <<YAML }
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
    create_patient_enforce: yes
    visits:
      - number: 1
        type: baseline
        description: 'Some preset for a visit'
YAML

      before(:each) do
        # TODO: #2644 - Refactor configuring Study
        tempfile = Tempfile.new('test.yml')
        tempfile.write(config_yaml)
        tempfile.close
        repo = GitConfigRepository.new
        repo.update_config_file(study.relative_config_file_path, tempfile, nil, "New configuration file for study #{study.id}")
        tempfile.unlink
      end

      it 'creates visits from template' do
        patient = Patient.create!(
          center: center,
          subject_id: '1234'
        )
        expect(patient.visits.count).to eq 1
      end
    end
  end
end
