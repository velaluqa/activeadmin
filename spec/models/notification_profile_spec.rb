RSpec.shared_examples 'filters changes' do |options|
  triggering_action = options[:triggering_action].andand.to_s || 'all'
  event_action = options[:event_action].andand.to_sym || :update

  context 'changing' do
    before(:each) do
      @pc1 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [[{
                                 foobar: {
                                   changes: {
                                     to: 'baz'
                                   }
                                 }
                               }]])
      @pc2 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [[{
                                 foobar: {
                                   changes: {
                                     to: 'bar'
                                   }
                                 }
                               }]])
      @pc3 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [[{
                                 foobar: {
                                   changes: {
                                     from: 'foo',
                                     to: 'baz'
                                   }
                                 }
                               }]])
      @pc4 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [[{
                                 foobar: {
                                   changes: {
                                     from: 'foo',
                                     to: 'bar'
                                   }
                                 }
                               }]])
      @pc5 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [[{
                                 foobar: {
                                   changes: {
                                     from: 'fu',
                                     to: 'baz'
                                   }
                                 }
                               }]])
      @pc6 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [
                      [{
                         foobar: {
                           changes: {
                             from: 'fu',
                             to: 'bar'
                           }
                         }
                       }]
                    ])
      @pc7 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [[{
                                 foobar: {
                                   changes: {
                                     from: 'foo'
                                   }
                                 }
                               }]])
      @pc8 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [
                      [{
                         foobar: {
                           changes: {
                             from: 'fu'
                           }
                         }
                       }]
                    ])
      @pc9 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    filters: [
                      [{
                        foobar: {
                          changes: {
                            from: 'foo',
                            to: nil
                          }
                        }
                      }]
                    ])
      @pc10 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     filters: [
                       [{
                         foobar: {
                           changes: {
                             from: nil,
                             to: 'bar'
                           }
                         }
                       }]
                     ])
      @pc11 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     filters: [
                       [
                         {
                           foobar: {
                             changes: {
                               to: 'bar'
                             }
                           }
                         }, {
                           foobaz: {
                             changes: {
                               from: 'bar',
                               to: 'buz'
                             }
                           }
                         }
                       ]
                     ])
      @pc12 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     filters: [
                       [{
                          foobar: {
                            changes: {
                              to: 'baz'
                            }
                          }
                        }],
                       [{
                          foobar: {
                            changes: {
                              to: 'bar'
                            }
                          }
                        }]
                     ])
      @pc13 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     filters: [
                       [
                         {
                           foobar: {
                             changes: {
                               to: 'baz'
                             }
                           }
                         }, {
                           foobaz: {
                             changes: {
                               from: 'bar',
                               to: 'buz'
                             }
                           }
                         }
                       ], [
                         {
                           foobar: {
                             changes: {
                               to: 'bar'
                             }
                           }
                         }
                       ]
                     ])
    end

    describe 'foobar(nil => "bar")' do
      before(:each) do
        @record = TestModel.create(foobar: 'bar', foobaz: 'buz')
        @profiles = NotificationProfile.triggered_by(
          event_action, @record,
          foobar: [nil, 'bar'],
          foobaz: [nil, 'buz']
        )
      end

      it 'does not return profile triggered by foobar(*any* => "baz")' do
        expect(@profiles).not_to include(@pc1)
      end
      it 'returns profile triggered by foobar(*any* => "bar")' do
        expect(@profiles).to include(@pc2)
      end
      it 'does not return profile triggered by foobar("foo" => "baz")' do
        expect(@profiles).not_to include(@pc3)
      end
      it 'does not return profile triggered by foobar("foo" => "bar")' do
        expect(@profiles).not_to include(@pc4)
      end
      it 'does not return profile triggered by foobar("fu" => "baz")' do
        expect(@profiles).not_to include(@pc5)
      end
      it 'does not return profile triggered by foobar("fu" => "bar")' do
        expect(@profiles).not_to include(@pc6)
      end
      it 'does not return profile triggered by foobar("foo" => *any*)' do
        expect(@profiles).not_to include(@pc7)
      end
      it 'does not return profile triggered by foobar("fu" => *any*)' do
        expect(@profiles).not_to include(@pc8)
      end
      it 'does not return profile triggered by foobar("foo" => nil)' do
        expect(@profiles).not_to include(@pc9)
      end
      it 'returns profile triggered by foobar(nil => "bar")' do
        expect(@profiles).to include(@pc10)
      end
      it 'does not return profile triggered by foobar(*any* => "bar") and foobaz("bar" => *any*)' do
        expect(@profiles).not_to include(@pc11)
      end
      it 'returns profile triggered by foobar(*any* => "baz") OR foobar(*any* => "bar")' do
        expect(@profiles).to include(@pc12)
      end
      it 'returns profile triggered by (foobar(*any* => "baz") AND foobaz("bar" => "buz")) OR foobar(*any* => "bar")' do
        expect(@profiles).to include(@pc13)
      end
    end
    describe 'change from `foo` to `bar`' do
      before(:each) do
        @record = TestModel.create(foobar: 'bar', foobaz: 'buz')
        @profiles = NotificationProfile.triggered_by(
          event_action, @record,
          foobar: ['foo', 'bar'],
          foobaz: ['bar', 'buz']
        )
      end

      it 'does not return profile triggered by foobar(*any* => "baz")' do
        expect(@profiles).not_to include(@pc1)
      end
      it 'returns profile triggered by foobar(*any* => "bar")' do
        expect(@profiles).to include(@pc2)
      end
      it 'does not return profile triggered by foobar("foo" => "baz")' do
        expect(@profiles).not_to include(@pc3)
      end
      it 'returns profile triggered by foobar("foo" => "bar")' do
        expect(@profiles).to include(@pc4)
      end
      it 'does not return profile triggered by foobar("fu" => "baz")' do
        expect(@profiles).not_to include(@pc5)
      end
      it 'does not return profile triggered by foobar("fu" => "bar")' do
        expect(@profiles).not_to include(@pc6)
      end
      it 'returns profile triggered by foobar("foo" => *any*)' do
        expect(@profiles).to include(@pc7)
      end
      it 'does not return profile triggered by foobar("fu" => *any*)' do
        expect(@profiles).not_to include(@pc8)
      end
      it 'does not return profile triggered by foobar("foo" => nil)' do
        expect(@profiles).not_to include(@pc9)
      end
      it 'does not return profile triggered by foobar(nil => "bar")' do
        expect(@profiles).not_to include(@pc10)
      end
      it 'returns profile triggered by foobar(*any* => "bar") and foobaz("bar" => *any*)' do
        expect(@profiles).to include(@pc11)
      end
      it 'does not return profile triggered by foobar(*any* => "baz") OR foobar(*any* => "bar")' do
        expect(@profiles).to include(@pc12)
      end
      it 'does not return profile triggered by (foobar(*any* => "baz") AND foobaz("bar" => "buz")) OR foobar(*any* => "bar")' do
        expect(@profiles).to include(@pc13)
      end
    end
    describe 'change from `foo` to `nil`' do
      before(:each) do
        @record = TestModel.create(foobar: nil)
        @profiles = NotificationProfile.triggered_by(
          event_action, @record,
          foobar: ['foo', nil]
        )
      end

      it 'does not return profile triggered by foobar(*any* => "baz")' do
        expect(@profiles).not_to include(@pc1)
      end
      it 'does not return profile triggered by foobar(*any* => "bar")' do
        expect(@profiles).not_to include(@pc2)
      end
      it 'does not return profile triggered by foobar("foo" => "baz")' do
        expect(@profiles).not_to include(@pc3)
      end
      it 'does not return profile triggered by foobar("foo" => "bar")' do
        expect(@profiles).not_to include(@pc4)
      end
      it 'does not return profile triggered by foobar("fu" => "baz")' do
        expect(@profiles).not_to include(@pc5)
      end
      it 'does not return profile triggered by foobar("fu" => "bar")' do
        expect(@profiles).not_to include(@pc6)
      end
      it 'returns profile triggered by foobar("foo" => *any*)' do
        expect(@profiles).to include(@pc7)
      end
      it 'does not return profile triggered by foobar("fu" => *any*)' do
        expect(@profiles).not_to include(@pc8)
      end
      it 'returns profile triggered by foobar("foo" => nil)' do
        expect(@profiles).to include(@pc9)
      end
      it 'does not return profile triggered by foobar(nil => "bar")' do
        expect(@profiles).not_to include(@pc10)
      end
      it 'does not return profile triggered by foobar(*any* => "bar") and foobaz("bar" => *any*)' do
        expect(@profiles).not_to include(@pc11)
      end
      it 'does not return profile triggered by foobar(*any* => "baz") OR foobar(*any* => "bar")' do
        expect(@profiles).not_to include(@pc12)
      end
      it 'does not return profile triggered by (foobar(*any* => "baz") AND foobaz("bar" => "buz")) OR foobar(*any* => "bar")' do
        expect(@profiles).not_to include(@pc13)
      end
    end
  end
end

RSpec.describe NotificationProfile do
  describe 'model' do
    it { should have_and_belong_to_many(:users) }
    it { should have_and_belong_to_many(:roles) }
    it { should have_many(:notifications) }

    it 'validates title' do
      expect(build(:notification_profile, title: nil)).not_to be_valid
      expect(build(:notification_profile, title: '')).not_to be_valid
    end

    it 'validates is_active' do
      expect(build(:notification_profile, is_active: nil)).not_to be_valid
      expect(build(:notification_profile, is_active: '')).not_to be_valid
    end

    it 'validates triggering_action' do
      expect(build(:notification_profile, triggering_action: nil)).not_to be_valid
      expect(build(:notification_profile, triggering_action: 'some')).not_to be_valid
      expect(build(:notification_profile, triggering_action: 'all')).to be_valid
      expect(build(:notification_profile, triggering_action: 'create')).to be_valid
      expect(build(:notification_profile, triggering_action: 'update')).to be_valid
      expect(build(:notification_profile, triggering_action: 'destroy')).to be_valid
    end

    it 'validates triggering_resource' do
      expect(build(:notification_profile, triggering_resource: nil)).not_to be_valid
      expect(build(:notification_profile, triggering_resource: '')).not_to be_valid
    end

    describe '#recipients' do
      before(:each) do
        @user1 = create(:user, email: 'foo@test.com')
        @user2 = create(:user, email: 'bar@test.com')
        @role = create(:role, users: [@user1])
        @profile1 = create(:notification_profile, users: [@user1], roles: [@role])
        @profile2 = create(:notification_profile, users: [@user2], roles: [@role])
        @profile3 = create(:notification_profile, users: [@user1, @user2], roles: [@role])
      end

      it 'returns unique recipients' do
        expect(@profile1.recipients).to contain(@user1, count: 1)
        expect(@profile1.recipients).to contain(@user2, count: 0)
        expect(@profile2.recipients).to contain(@user1, count: 1)
        expect(@profile2.recipients).to contain(@user2, count: 1)
        expect(@profile3.recipients).to contain(@user1, count: 1)
        expect(@profile3.recipients).to contain(@user2, count: 1)
      end
    end
  end

  describe 'scope ::recipients_with_pending' do
    describe 'without throttled option' do
      before(:each) do
        @user1 = create(:user)
        @user2 = create(:user)
        @profile = create(:notification_profile, users: [@user1, @user2])
        create(:notification, notification_profile: @profile, user: @user1)
        create(:notification, notification_profile: @profile, user: @user1)
        create(:notification, notification_profile: @profile, user: @user2, email_sent_at: 1.hour.ago, created_at: 2.hours.ago)

        @recipients = @profile.recipients_with_pending
      end

      it 'returns all users with pending notifications for profile' do
        expect(@recipients).to contain(@user1, count: 1)
        expect(@recipients).not_to include(@user2)
      end
    end

    describe 'with throttled option and' do
      describe 'profiles maximum throttling delay is minimum' do
        before(:each) do
          Rails.application.config.maximum_email_throttling_delay = 24*60*60

          @user1 = create(:user, email_throttling_delay: 24*60*60)
          @user2 = create(:user)
          @profile1 = create(:notification_profile, users: [@user1, @user2], maximum_email_throttling_delay: 60*60)
          @profile2 = create(:notification_profile, users: [@user1, @user2])
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user2)
          create(:notification, notification_profile: @profile2, user: @user1)
          create(:notification, notification_profile: @profile2, user: @user2)
        end

        it 'returns only users with pending notifications matching the throttling settings for the profile-user-combination' do
          expect(@profile1.recipients_with_pending(throttle: 60*60)).to contain(@user1, count: 1)
          expect(@profile1.recipients_with_pending(throttle: 60*60)).to contain(@user2, count: 1)

          expect(@profile1.recipients_with_pending(throttle: 24*60*60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 24*60*60)).not_to include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 60*60)).to_not include(@user1)
          expect(@profile2.recipients_with_pending(throttle: 60*60)).to_not include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 24*60*60)).to contain(@user1, count: 1)
          expect(@profile2.recipients_with_pending(throttle: 24*60*60)).to contain(@user2, count: 1)
        end
      end

      describe 'user throttling delay is minimum' do
        before(:each) do
          Rails.application.config.maximum_email_throttling_delay = 24*60*60

          @user1 = create(:user, email_throttling_delay: 60*60)
          @user2 = create(:user)
          @profile1 = create(:notification_profile, users: [@user1, @user2])
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user2)
        end

        it 'returns only users with pending notifications matching the throttling settings for the profile-user-combination' do
          expect(@profile1.recipients_with_pending(throttle: 60*60)).to contain(@user1, count: 1)
          expect(@profile1.recipients_with_pending(throttle: 60*60)).not_to include(@user2)

          expect(@profile1.recipients_with_pending(throttle: 24*60*60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 24*60*60)).to contain(@user2, count: 1)
        end
      end

      describe 'system maximum throttling delay is minimum' do
        before(:each) do
          Rails.application.config.maximum_email_throttling_delay = 60*60

          @user1 = create(:user, email_throttling_delay: 7*24*60*60)
          @user2 = create(:user)
          @profile1 = create(:notification_profile, users: [@user1])
          @profile2 = create(:notification_profile, users: [@user1, @user2], maximum_email_throttling_delay: 24*60*60)
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user2)
          create(:notification, notification_profile: @profile2, user: @user1)
          create(:notification, notification_profile: @profile2, user: @user2)
        end

        it 'returns only users with pending notifications matching the throttling settings for the profile-user-combination' do
          expect(@profile1.recipients_with_pending(throttle: 60*60)).to contain(@user1, count: 1)
          expect(@profile1.recipients_with_pending(throttle: 60*60)).to contain(@user2, count: 1)

          expect(@profile1.recipients_with_pending(throttle: 24*60*60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 24*60*60)).not_to include(@user2)

          expect(@profile1.recipients_with_pending(throttle: 7*24*60*60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 7*24*60*60)).not_to include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 60*60)).to contain(@user1, count: 1)
          expect(@profile2.recipients_with_pending(throttle: 60*60)).to contain(@user2, count: 1)

          expect(@profile2.recipients_with_pending(throttle: 24*60*60)).not_to include(@user1)
          expect(@profile2.recipients_with_pending(throttle: 24*60*60)).not_to include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 7*24*60*60)).not_to include(@user1)
          expect(@profile2.recipients_with_pending(throttle: 7*24*60*60)).not_to include(@user2)
        end
      end
    end
  end

  with_model :MultiModel do
    table do |t|
      t.string :foo, null: true
      t.references :test_model
    end
    model do
      belongs_to :test_model
    end
  end

  with_model :ExtraModel do
    table do |t|
      t.string :foo, null: true
    end
    model do
      has_paper_trail class_name: 'Version'

      has_one :test_model
    end
  end

  with_model :TestModel do
    table do |t|
      t.string :foobar, null: true
      t.string :foobaz, null: true
      t.references :extra_model
    end
    model do
      has_many :multi_models
      belongs_to :extra_model
    end
  end

  describe '::triggered_by' do
    before(:each) do
      @p1 = create(:notification_profile, triggering_action: 'all', triggering_resource: 'TestModel')
      @p2 = create(:notification_profile, triggering_action: 'create', triggering_resource: 'TestModel')
      @p3 = create(:notification_profile, triggering_action: 'update', triggering_resource: 'TestModel')
      @p4 = create(:notification_profile, triggering_action: 'destroy', triggering_resource: 'TestModel')

      @pe1 = create(:notification_profile, triggering_action: 'all', triggering_resource: 'ExtraModel')
      @pe2 = create(:notification_profile, triggering_action: 'create', triggering_resource: 'ExtraModel')
      @pe3 = create(:notification_profile, triggering_action: 'update', triggering_resource: 'ExtraModel')
      @pe4 = create(:notification_profile, triggering_action: 'destroy', triggering_resource: 'ExtraModel')

      @record = TestModel.create
      @record2 = ExtraModel.create
    end

    it 'is defined' do
      expect(NotificationProfile).to respond_to('triggered_by')
    end

    describe ':create TestModel' do
      before(:each) do
        @profiles = NotificationProfile.triggered_by(:create, @record)
      end
      it 'returns profiles triggered for all actions' do
        expect(@profiles).to include(@p1)
      end
      it 'returns profiles triggered for :create actions' do
        expect(@profiles).to include(@p2)
      end
      it 'does not return profiles triggered for :update' do
        expect(@profiles).not_to include(@p3)
      end
      it 'does not return profiles triggered for :destroy' do
        expect(@profiles).not_to include(@p4)
      end
      it 'does not return any profile triggered for ExtraModel' do
        expect(@profiles).not_to include(@pe1)
        expect(@profiles).not_to include(@pe2)
        expect(@profiles).not_to include(@pe3)
        expect(@profiles).not_to include(@pe4)
      end

      include_examples 'filters changes', triggering_action: 'all', event_action: :create
      include_examples 'filters changes', triggering_action: 'create', event_action: :create
    end

    describe ':update TestModel' do
      before(:each) do
        @profiles = NotificationProfile.triggered_by(:update, @record)
      end
      it 'returns profiles triggered for all actions' do
        expect(@profiles).to include(@p1)
      end
      it 'returns profiles triggered for :create actions' do
        expect(@profiles).not_to include(@p2)
      end
      it 'does not return profiles triggered for :update' do
        expect(@profiles).to include(@p3)
      end
      it 'does not return profiles triggered for :destroy' do
        expect(@profiles).not_to include(@p4)
      end
      it 'does not return any profile triggered for ExtraModel' do
        expect(@profiles).not_to include(@pe1)
        expect(@profiles).not_to include(@pe2)
        expect(@profiles).not_to include(@pe3)
        expect(@profiles).not_to include(@pe4)
      end

      include_examples 'filters changes', triggering_action: 'all', event_action: :update
      include_examples 'filters changes', triggering_action: 'update', event_action: :update
    end

    describe ':destroy TestModel' do
      before(:each) do
        @profiles = NotificationProfile.triggered_by(:destroy, @record)
      end
      it 'returns profiles triggered for all actions' do
        expect(@profiles).to include(@p1)
      end
      it 'returns profiles triggered for :create actions' do
        expect(@profiles).not_to include(@p2)
      end
      it 'does not return profiles triggered for :update' do
        expect(@profiles).not_to include(@p3)
      end
      it 'does not return profiles triggered for :destroy' do
        expect(@profiles).to include(@p4)
      end
      it 'does not return any profile triggered for ExtraModel' do
        expect(@profiles).not_to include(@pe1)
        expect(@profiles).not_to include(@pe2)
        expect(@profiles).not_to include(@pe3)
        expect(@profiles).not_to include(@pe4)
      end

      include_examples 'filters changes', triggering_action: 'all', event_action: :destroy
      include_examples 'filters changes', triggering_action: 'destroy', event_action: :destroy
    end
  end

  describe '#trigger' do
    it 'is defined' do
      expect(NotificationProfile.new).to respond_to('trigger')
    end

    before(:each) do
      @user1 = create(:user)
      @user2 = create(:user)

      @profile1 = create(:notification_profile, users: [@user1, @user2], triggering_resource: 'TestModel', only_authorized_recipients: false)
      @profile2 = create(:notification_profile, users: [@user1, @user2], triggering_resource: 'TestModel', only_authorized_recipients: true)
      @record = TestModel.create(foobar: 'foo')
    end

    it 'creates notification for system actions' do
      allow(::PaperTrail).to receive(:whodunnit) { nil }
      expect do
        @profile1.trigger(:create, @record)
      end.to change(Notification, :count).by(2)
      expect(Notification.where(user: @user1)).to exist
      expect(Notification.where(user: @user2)).to exist
    end

    it 'creates notification for others actions' do
      allow(::PaperTrail).to receive(:whodunnit) { @user2 }
      expect do
        @profile1.trigger(:create, @record)
      end.to change(Notification, :count).by(1)
      expect(Notification.where(user: @user1)).to exist
    end

    it 'does not create a notification for my own action' do
      allow(::PaperTrail).to receive(:whodunnit) { @user2 }
      expect do
        @profile1.trigger(:create, @record)
      end.to change(Notification, :count).by(1)
      expect(Notification.where(user: @user2)).not_to exist
    end

    it 'creates notification only for authorized users' do
      allow_any_instance_of(Ability).to receive(:can?) { |ability, activity, subject|
        ability.current_user == @user1
      }
      expect do
        @profile2.trigger(:create, @record)
      end.to change(Notification, :count).by(1)
      expect(Notification.where(user: @user1)).to exist
      expect(Notification.where(user: @user2)).not_to exist
    end

    describe 'for model with versions' do
      before(:each) do
        @user = create(:user)
        @profile = create(:notification_profile, users: [@user], triggering_resource: 'ExtraModel')
        @record = ExtraModel.create(foo: 'foo')
        allow_any_instance_of(Ability).to receive(:can?).and_return(true)
      end

      it 'creates a notification with a version after create' do
        expect do
          @profile.trigger(:create, @record)
        end.to change(Notification, :count).by(1)
        notification = Notification.last
        expect(notification.version).to eq @record.versions.last
      end

      it 'creates a notification with a version after update' do
        @record.foo = 'bar'
        @record.save!
        expect do
          @profile.trigger(:update, @record)
        end.to change(Notification, :count).by(1)
        notification = Notification.last
        expect(notification.version).to eq @record.versions.last
      end
    end
  end
end
