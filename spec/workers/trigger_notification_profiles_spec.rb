describe TriggerNotificationProfiles do
  it { is_expected.to be_processed_in :notifications }
  it { is_expected.to be_retryable(5) }

  describe 'for :create version' do
    let!(:user) { create(:user) }
    let!(:profile) do
      create(
        :notification_profile,
        triggering_actions: ['create'],
        triggering_resource: 'Study',
        is_enabled: true,
        filters: [[{
                     name: {
                       equal: 'Bar Study'
                     }
                   }]],
        users: [user],
        only_authorized_recipients: false
      )
    end
    before(:each) do
      @study = create(:study, name: 'Bar Study')
    end
    let(:version) { Version.last }

    it 'creates respective notifications' do
      TriggerNotificationProfiles.new.perform(version.id)
      expect(Notification.all.map(&:attributes)).to include(include('version_id' => version.id))
    end
  end

  describe 'for :update version' do
    let!(:user) { create(:user) }
    let!(:profile) do
      create(
        :notification_profile,
        triggering_actions: ['update'],
        triggering_resource: 'Study',
        is_enabled: true,
        filters: [[{
                     name: {
                       equal: 'Bar Study'
                     }
                   }]],
        users: [user],
        only_authorized_recipients: false
      )
    end
    before(:each) do
      @study = create(:study, name: 'Foo Study')
      @study.name = 'Bar Study'
      @study.save!
    end
    let(:version) { Version.last }

    it 'creates respective notifications' do
      TriggerNotificationProfiles.new.perform(version.id)
      expect(Notification.all.map(&:attributes)).to include(include('version_id' => version.id))
    end
  end

  describe 'for :destroy version' do
    let!(:user) { create(:user) }
    let!(:profile) do
      create(
        :notification_profile,
        triggering_actions: ['destroy'],
        triggering_resource: 'Study',
        is_enabled: true,
        filters: [[{
                     name: {
                       equal: 'Bar Study'
                     }
                   }]],
        users: [user],
        only_authorized_recipients: false
      )
    end
    before(:each) do
      @study = create(:study, name: 'Bar Study')
      @study.destroy!
    end
    let(:version) { Version.last }

    it 'creates respective notifications' do
      TriggerNotificationProfiles.new.perform(version.id)
      expect(Notification.all.map(&:attributes)).to include(include('version_id' => version.id))
    end
  end
end
