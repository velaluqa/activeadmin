require_dependency 'migration/add_missing_version_item_name'

describe Migration::AddMissingVersionItemName do
  describe 'run' do
    def version_item_name_for(event, type, item)
      Version.where(
        item_type: type,
        item_id: item.id,
        event: event
      ).first.item_name
    end

    before(:all) do
      Version.skip_callback(:save, :before, :add_item_name_as_string)
    end

    after(:all) do
      Version.set_callback(:save, :before, :add_item_name_as_string)
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
      @permission = create(:permission, activity: "create", subject: "Patient", role: @role)
      @required_series = create(:required_series, name: "test_rs", visit: @visit)
      [
        @study,
        @center,
        @patient,
        @visit,
        @image_series,
        @image,
        @user_role,
        @role,
        @user,
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

    before(:all) do
      Migration::AddMissingVersionItemName.run
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
end
