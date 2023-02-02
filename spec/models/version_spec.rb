RSpec.describe Version do
  it { should have_many(:notifications) }

  describe "before save callback" do
    def version_item_name_for(event, type, item)
      Version.where(
        item_type: type,
        item_id: item.id,
        event: event
      ).first.item_name
    end

    before(:all) do
      @study = create(:study, name: "test_study")
      @center = create(:center, code: "100",  name: "test_center" )
      @patient = create(:patient, subject_id: "100", center: @center)
      @visit = create(:visit, visit_number: 1, patient: @patient)
      @image_series = create(:image_series, name: "test_series", patient: @patient)
      @image = create(:image, image_series: @image_series)
      @role = create(:role, title: "test_role")
      @user = create(:user, name: "Max Mustermann")
      @user_role = create(:user_role, user: @user, role: @role)
      @email_template = create(:email_template, name: "test_template")
      @notification_profile = create(
        :notification_profile,
        title: "test_profile",
        email_template: @email_template,
        users: [@user],
        roles: [@role]
      )
      @notification_profile_role = @notification_profile.notification_profile_roles.first
      @notification_profile_user = @notification_profile.notification_profile_users.first
      @form_definition = create(:form_definition, name: "test_definition",id: 1)
      @configuration = create(:configuration, configurable_type: "FormDefinition", configurable_id: @form_definition.id)
      @form_answer = create(:form_answer, form_definition: @form_definition)
      @form_session = create(:form_session, name: "test_session")
      @notification = create(:notification, notification_profile: @notification_profile)
      @permission = create(:permission, role: @role, activity: "create", subject: "Patient")
      @required_series = create(:required_series, name: "test_rs", visit: @visit)
      [
        @study,
        @center,
        @patient,
        @visit,
        @image_series,
        @image,
        @role,
        @user,
        @user_role,
        @email_template,
        @notification_profile,
        @form_definition,
        @configuration,
        @form_answer,
        @form_session,
        @notification,
        @permission,
        @required_series
      ].reverse.each(&:destroy)
    end

    after(:all) do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'saves the `item_name` to the `Study` version' do
      expect(version_item_name_for("create", "Study", @study))
        .to eq("test_study")
      expect(version_item_name_for("destroy", "Study", @study))
        .to eq("test_study")
    end

    it 'saves the `item_name` to the `Center` version' do
      expect(version_item_name_for("create", "Center", @center))
        .to eq("test_center")
      expect(version_item_name_for("destroy", "Center", @center))
        .to eq("test_center")
    end

    it 'saves the `item_name` to the `Patient` version' do
      expect(version_item_name_for("create", "Patient", @patient))
        .to eq("100100")
      expect(version_item_name_for("destroy", "Patient", @patient))
        .to eq("100100")
    end

    it 'saves the `item_name` to the `Visit` version' do
      expect(version_item_name_for("create", "Visit", @visit))
        .to eq("100100#1")
      expect(version_item_name_for("destroy", "Visit", @visit))
        .to eq("100100#1")
    end

    it 'saves the `item_name` to the `Image` version' do
      expect(version_item_name_for("create", "Image", @image))
        .to eq("Image of test_series")
      expect(version_item_name_for("destroy", "Image", @image))
        .to eq("Image of test_series")
    end

    it 'saves the `item_name` to the `ImageSeries` version' do
      expect(version_item_name_for("create", "ImageSeries", @image_series))
        .to eq("test_series")
      expect(version_item_name_for("destroy", "ImageSeries", @image_series))
        .to eq("test_series")
    end

    it 'saves the `item_name` to the `Role` version' do
      expect(version_item_name_for("create", "Role", @role))
        .to eq("test_role")
      expect(version_item_name_for("destroy", "Role", @role))
        .to eq("test_role")
    end

    it 'saves the `item_name` to the `User` version' do
      expect(version_item_name_for("create", "User", @user))
        .to eq("Max Mustermann")
      expect(version_item_name_for("destroy", "User", @user))
        .to eq("Max Mustermann")
    end

    it 'saves the `item_name` to the `UserRole` version' do
      expect(version_item_name_for("create", "UserRole", @user_role))
        .to eq("test_role")
      expect(version_item_name_for("destroy", "UserRole", @user_role))
        .to eq("test_role")
    end

    it 'saves the `item_name` to the `EmailTemplate` version' do
      expect(version_item_name_for("create", "EmailTemplate", @email_template))
        .to eq("test_template")
      expect(version_item_name_for("destroy", "EmailTemplate", @email_template))
        .to eq("test_template")
    end

    it 'saves the `item_name` to the `NotificationProfile` version' do
      expect(version_item_name_for("create", "NotificationProfile", @notification_profile))
        .to eq("test_profile")
      expect(version_item_name_for("destroy", "NotificationProfile", @notification_profile))
        .to eq("test_profile")
    end

    it 'saves the `item_name` to the `NotificationProfileRole` version' do
      expect(version_item_name_for("create", "NotificationProfileRole", @notification_profile_role))
        .to eq("test_role")
      expect(version_item_name_for("destroy", "NotificationProfileRole", @notification_profile_role))
        .to eq("test_role")
    end

    it 'saves the `item_name` to the `NotificationProfileUser` version' do
      expect(version_item_name_for("create", "NotificationProfileUser", @notification_profile_user))
        .to eq("Max Mustermann")
      expect(version_item_name_for("destroy", "NotificationProfileUser", @notification_profile_user))
        .to eq("Max Mustermann")
    end

    it 'saves the `item_name` to the `FormDefinition` version' do
      expect(version_item_name_for("create", "FormDefinition", @form_definition))
        .to eq("test_definition")
      expect(version_item_name_for("destroy", "FormDefinition", @form_definition))
        .to eq("test_definition")
    end
    
    it 'saves the `item_name` to the `Configuration` version' do
      expect(version_item_name_for("create", "Configuration", @configuration))
        .to eq("FormDefinition: test_definition")
      expect(version_item_name_for("destroy", "Configuration", @configuration))
        .to eq("FormDefinition: test_definition")
    end

    it 'saves the `item_name` to the `FormAnswer` version' do
      expect(version_item_name_for("create", "FormAnswer", @form_answer))
        .to eq("Form Answer: test_definition")
      expect(version_item_name_for("destroy", "FormAnswer", @form_answer))
        .to eq("Form Answer: test_definition")
    end
    
    it 'saves the `item_name` to the `FormSession` version' do
      expect(version_item_name_for("create", "FormSession", @form_session))
        .to eq("test_session")
      expect(version_item_name_for("destroy", "FormSession", @form_session))
        .to eq("test_session")
    end

    it 'saves the `item_name` to the `Notification` version' do
      expect(version_item_name_for("create", "Notification", @notification))
        .to eq("Notification[create Visit]")
      expect(version_item_name_for("destroy", "Notification", @notification))
        .to eq("Notification[create Visit]")
    end

    it 'saves the `item_name` to the `Permission` version' do
      expect(version_item_name_for("create", "Permission", @permission))
        .to eq("test_role create Patient")
      expect(version_item_name_for("destroy", "Permission", @permission))
        .to eq("test_role create Patient")
    end

    it 'saves the `item_name` to the `RequiredSeries` version' do
      expect(version_item_name_for("create", "RequiredSeries", @required_series))
        .to eq("100100#1 test_rs")
      expect(version_item_name_for("destroy", "RequiredSeries", @required_series))
        .to eq("100100#1 test_rs")
    end
  end

  describe '::ordered_find_each' do
    before(:each) do
      expect(Version.count).to eq(0)
      250.times { create(:study) }
      expect(Version.count).to eq(250)
      @last_id = Version.last.id
      @first_id = Version.first.id
    end

    it 'finds all ordered' do
      versions = Version
                 .select(:id)
                 .where('"versions"."id" >= ?', @first_id)
                 .where('"versions"."id" <= ?', @last_id - 5)
                 .order(Arel.sql('"versions"."id" DESC'))
      ids = []
      versions.ordered_find_each do |version|
        ids.push(version.id)
        # Ensure that the batches are ordered correctly even when a
        # new version is added.
        create(:user) if version.id == 50
      end
      # expect(ids.length).to eq(245)
      expect(ids).to eq((@first_id..(@last_id - 5)).to_a.reverse)
    end
  end

  describe 'scope ::of_study_resource' do
    let!(:study) { create(:study) }
    let!(:study_version) { Version.last }
    let!(:center) { create(:center, study: study) }
    let!(:center_version) { Version.last }
    let!(:patient) { create(:patient, center: center) }
    let!(:patient_version) { Version.last }
    let!(:visit) { create(:visit, patient: patient) }
    let!(:visit_version) { Version.last }
    let!(:required_series) { create(:required_series, visit: visit, name: 'SPECT_1')}
    let!(:required_series_version) { Version.last }
    let!(:image_series) { create(:image_series, visit: visit, patient: patient) }
    let!(:image_series_version) { Version.last }

    describe 'with resource `Patient`' do
      let(:result) { Version.of_study_resource(study, 'Patient') }

      it 'includes patient version' do
        expect(result).to include(patient_version)
        expect(result).not_to include(visit_version)
        expect(result).not_to include(image_series_version)
        expect(result).not_to include(required_series_version)
      end
    end

    describe 'with resource `Visit`' do
      let(:result) { Version.of_study_resource(study, 'Visit') }

      it 'includes visit version' do
        expect(result).not_to include(patient_version)
        expect(result).to include(visit_version)
        expect(result).not_to include(image_series_version)
        expect(result).not_to include(required_series_version)
      end
    end

    describe 'with resource `ImageSeries`' do
      let(:result) { Version.of_study_resource(study, 'ImageSeries') }

      it 'includes image_series version' do
        expect(result).not_to include(patient_version)
        expect(result).not_to include(visit_version)
        expect(result).to include(image_series_version)
        expect(result).not_to include(required_series_version)
      end
    end

    describe 'with resource `RequiredSeries`' do
      let(:result) { Version.of_study_resource(study, 'RequiredSeries') }

      it 'includes required_series version' do
        expect(result).not_to include(patient_version)
        expect(result).not_to include(visit_version)
        expect(result).not_to include(image_series_version)
        expect(result).to include(required_series_version)
      end
    end
  end

  describe '#complete_changes' do
    describe 'for create' do
      let!(:version) do
        Version.create(
          event: 'create',
          item_type: 'Study',
          item_id: 8,
          object: nil,
          object_changes: {
            'id'         => [nil, 8],
            'name'       => [nil, 'Study 1'],
            'created_at' => [nil, '2017-02-24T09:37:31.984Z'],
            'updated_at' => [nil, '2017-02-24T09:37:31.984Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'         => [nil, 8],
          'name'       => [nil, 'Study 1'],
          'created_at' => [nil, '2017-02-24T09:37:31.984Z'],
          'updated_at' => [nil, '2017-02-24T09:37:31.984Z']
        }
        expect(version.complete_changes).to eq(expected_changes)
      end
    end
    describe 'for update' do
      let!(:version) do
        Version.create(
          event: 'update',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: {
            'name'       => ['Study 1', 'Foo Study'],
            'updated_at' => ['2017-02-24T09:37:31.984Z', '2017-02-24T09:41:31.675Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'name'       => ['Study 1', 'Foo Study'],
          'updated_at' => ['2017-02-24T09:37:31.984Z', '2017-02-24T09:41:31.675Z']
        }
        expect(version.complete_changes).to eq(expected_changes)
      end
    end
    describe 'for destroy' do
      let!(:version) do
        Version.create(
          event: 'destroy',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: nil
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'         => [8, nil],
          'name'       => ['Study 1', nil],
          'state'      => [0, nil],
          'created_at' => ['2017-02-24T09:37:31.984Z', nil],
          'updated_at' => ['2017-02-24T09:37:31.984Z', nil]
        }
        expect(version.complete_changes).to eq(expected_changes)
      end
    end
  end

  describe '#complete_attributes' do
    describe 'for create' do
      let!(:version) do
        Version.create(
          event: 'create',
          item_type: 'Study',
          item_id: 8,
          object: nil,
          object_changes: {
            'id'         => [nil, 8],
            'name'       => [nil, 'Study 1'],
            'created_at' => [nil, '2017-02-24T09:37:31.984Z'],
            'updated_at' => [nil, '2017-02-24T09:37:31.984Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'         => 8,
          'name'       => 'Study 1',
          'created_at' => '2017-02-24T09:37:31.984Z',
          'updated_at' => '2017-02-24T09:37:31.984Z'
        }
        expect(version.complete_attributes).to eq(expected_changes)
      end
    end
    describe 'for update' do
      let!(:version) do
        Version.create(
          event: 'update',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: {
            'name'       => ['Study 1', 'Foo Study'],
            'updated_at' => ['2017-02-24T09:37:31.984Z', '2017-02-24T09:41:31.675Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'                   => 8,
          'name'                 => 'Foo Study',
          'state'                => 0,
          'created_at'           => '2017-02-24T09:37:31.984Z',
          'updated_at'           => '2017-02-24T09:41:31.675Z',
          'domino_db_url'        => nil,
          'locked_version'       => nil,
          'domino_server_name'   => nil,
          'notes_links_base_uri' => nil
        }
        expect(version.complete_attributes).to eq(expected_changes)
      end
    end
    describe 'for destroy' do
      let!(:version) do
        Version.create(
          event: 'destroy',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: nil
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'                   => 8,
          'name'                 => 'Study 1',
          'state'                => 0,
          'created_at'           => '2017-02-24T09:37:31.984Z',
          'updated_at'           => '2017-02-24T09:37:31.984Z',
          'domino_db_url'        => nil,
          'locked_version'       => nil,
          'domino_server_name'   => nil,
          'notes_links_base_uri' => nil
        }
        expect(version.complete_attributes).to eq(expected_changes)
      end
    end
  end

  describe 'callback', transactional_spec: true do
    with_model :ObservableModel do
      table do |t|
        t.string :title
        t.timestamps null: false
      end
      model do
        has_paper_trail class_name: 'Version'
      end
    end

    describe 'on create' do
      it 'triggers notification profiles' do
        model = ObservableModel.create(title: 'foo')
        expect(TriggerNotificationProfiles).to have_enqueued_sidekiq_job(model.versions.last.id)
      end
    end
    describe 'on update' do
      it 'triggers notification profiles' do
        model = ObservableModel.create(title: 'foo')
        model.title = 'bar'
        model.save!
        expect(TriggerNotificationProfiles).to have_enqueued_sidekiq_job(model.versions.last.id)
      end
    end
    describe 'on destroy' do
      it 'triggers notification profiles' do
        model = ObservableModel.create(title: 'foo')
        model.destroy
        expect(TriggerNotificationProfiles).to have_enqueued_sidekiq_job(Version.last.id)
      end
    end
  end
end
