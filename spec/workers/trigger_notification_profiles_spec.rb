describe TriggerNotificationProfiles do
  with_model :NotificationObservableModel do
    table do |t|
      t.string :title
      t.timestamps null: false
    end
    model do
      include NotificationObservable
    end
  end
  
  it { is_expected.to be_processed_in :notifications }
  it { is_expected.to be_retryable(5) }

  it 'enqueues another job' do
    TriggerNotificationProfiles.perform_async('create', 'Study', 1, {})
    expect(TriggerNotificationProfiles).to have_enqueued_sidekiq_job('create', 'Study', 1, {})
  end

  before(:each) do
    @profile = create(:notification_profile, triggering_resource: 'NotificationObservableModel')
    @model = NotificationObservableModel.create(title: 'foo')
  end

  it 'triggers respective NotificationProfile' do
    expect(NotificationProfile).to receive(:triggered_by).at_least(1).and_return([@profile])
    expect(@profile).to receive(:trigger).with(:update, @model)
    TriggerNotificationProfiles.new
      .perform('update', "NotificationObservableModel", @model.id, YAML.dump({title: [nil, 'foo']}.with_indifferent_access))
  end
end
