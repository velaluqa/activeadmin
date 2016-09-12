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
      expect(NotificationProfile)
        .to receive(:triggered_by)
             .at_least(1)
             .and_return([@profile])
    end

    describe 'after create' do
      it 'executes triggers on triggerable notification profiles' do
        model = NotificationObservableModel.new(title: 'foo')
        expect(@profile).to receive(:trigger).with(:create, model)
        model.save
      end
    end

    describe 'after update' do
      it 'executes triggers on triggerable notification profiles' do
        model = NotificationObservableModel.create(title: 'foo')
        model.title = 'bar'
        expect(@profile).to receive(:trigger).with(:update, model)
        model.save
      end
    end

    describe 'after destroy' do
      it 'executes triggers on triggerable notification profiles' do
        model = NotificationObservableModel.create(title: 'foo')
        expect(@profile).to receive(:trigger).with(:destroy, model)
        model.destroy
      end
    end
  end

  it 'marks including model class as notification_observable' do
    expect(NotificationObservableModel.notification_observable?).to be_truthy
    expect(NotNotificationObservableModel.notification_observable?).to be_falsy
  end
end
