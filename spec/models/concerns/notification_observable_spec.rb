RSpec.describe NotificationObservable do
  with_model :NotificationObservableModel do
    table do |t|
      t.string :title
      t.timestamps null: false
    end
    model do
      include NotificationObservable
    end
  end

  with_model :NotNotificationObservableModel do
    table do |t|
      t.string :title
      t.timestamps null: false
    end
    model do
    end
  end

  describe 'callback' do
    before(:each) do
      @profile = create(:notification_profile,
                        triggering_resource: 'NotificationObservableModel')
    end

    describe 'after create' do
      it 'executes triggers on triggerable notification profiles' do
        model = NotificationObservableModel.create(title: 'foo')
        expect(TriggerNotificationProfiles)
          .to have_enqueued_sidekiq_job(:create, model.class.to_s, model.id,
                                        YAML.dump(
                                          {
                                            'title' => [nil, 'foo'],
                                            'created_at' => [nil, model.created_at],
                                            'updated_at' => [nil, model.created_at],
                                            'id' => [nil, 1]
                                          }.with_indifferent_access
                                        ))
      end
    end

    describe 'after update' do
      it 'executes triggers on triggerable notification profiles' do
        model = NotificationObservableModel.create(title: 'foo')
        model.title = 'bar'
        model.save
        expect(TriggerNotificationProfiles)
          .to have_enqueued_sidekiq_job('update', model.class.to_s,
                                        model.id,
                                        YAML.dump(
                                          {
                                            'title' => ['foo', 'bar'],
                                            'updated_at' => [model.created_at, model.updated_at]
                                          }.with_indifferent_access
                                       ))
      end
    end

    describe 'after destroy' do
      it 'executes triggers on triggerable notification profiles' do
        model = NotificationObservableModel.create(title: 'foo')
        model.destroy
        expect(TriggerNotificationProfiles)
          .to have_enqueued_sidekiq_job('destroy', model.class.to_s, model.id, YAML.dump({}.with_indifferent_access))
      end
    end
  end

  it 'marks including model class as notification_observable' do
    expect(NotificationObservableModel.notification_observable?).to be_truthy
    expect(NotNotificationObservableModel.notification_observable?).to be_falsy
  end

  it 'keeps all observable resources in a list' do
    expect(NotificationObservable.resources).to include(NotificationObservableModel)
    expect(NotificationObservable.resources).not_to include(NotNotificationObservableModel)
  end
end
