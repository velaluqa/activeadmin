RSpec.shared_examples 'filters changes' do |options|
  triggering_actions = options[:triggering_actions].andand.map(&:to_s) || %w[create update destroy]
  event_action = options[:event_action].andand.to_sym || :update

  context 'changing' do
    before(:each) do
      @pc1 = create(:notification_profile,
                    triggering_actions: triggering_actions,
                    triggering_resource: 'TestModel',
                    filters: [[{
                      foobar: {
                        changes: {
                          to: 'baz'
                        }
                      }
                    }]])
      @pc2 = create(:notification_profile,
                    triggering_actions: triggering_actions,
                    triggering_resource: 'TestModel',
                    filters: [[{
                      foobar: {
                        changes: {
                          to: 'bar'
                        }
                      }
                    }]])
      @pc3 = create(:notification_profile,
                    triggering_actions: triggering_actions,
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
                    triggering_actions: triggering_actions,
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
                    triggering_actions: triggering_actions,
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
                    triggering_actions: triggering_actions,
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
                    triggering_actions: triggering_actions,
                    triggering_resource: 'TestModel',
                    filters: [[{
                      foobar: {
                        changes: {
                          from: 'foo'
                        }
                      }
                    }]])
      @pc8 = create(:notification_profile,
                    triggering_actions: triggering_actions,
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
                    triggering_actions: triggering_actions,
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
                     triggering_actions: triggering_actions,
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
                     triggering_actions: triggering_actions,
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
                     triggering_actions: triggering_actions,
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
                     triggering_actions: triggering_actions,
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
          event_action,
          'TestModel',
          @record,
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
          event_action,
          'TestModel',
          @record,
          foobar: %w[foo bar],
          foobaz: %w[bar buz]
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
          event_action,
          'TestModel',
          @record,
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
    it { should have_many(:notification_profile_users) }
    it { should have_many(:users) }
    it { should have_many(:notification_profile_roles) }
    it { should have_many(:roles) }
    it { should have_many(:notifications) }
    it { should belong_to(:email_template) }

    it 'validates title' do
      expect(build(:notification_profile, title: nil)).not_to be_valid
      expect(build(:notification_profile, title: '')).not_to be_valid
    end

    it 'validates triggering_action' do
      expect(build(:notification_profile, triggering_actions: nil)).not_to be_valid
      expect(build(:notification_profile, triggering_actions: %w[some])).not_to be_valid
      expect(build(:notification_profile, triggering_actions: %w[create update destroy])).to be_valid
      expect(build(:notification_profile, triggering_actions: %w[create])).to be_valid
      expect(build(:notification_profile, triggering_actions: %w[update])).to be_valid
      expect(build(:notification_profile, triggering_actions: %w[destroy])).to be_valid
    end

    it 'validates triggering_resource' do
      expect(build(:notification_profile, triggering_resource: nil)).not_to be_valid
      expect(build(:notification_profile, triggering_resource: '')).not_to be_valid
    end

    it 'validates email_template type' do
      template1 = build(:email_template, email_type: 'NotificationProfile')
      expect(build(:notification_profile, email_template: template1)).to be_valid
      template2 = build(:email_template, email_type: 'Notification')
      expect(build(:notification_profile, email_template: template2)).not_to be_valid
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
          allow(Rails.application.config).to receive(:maximum_email_throttling_delay).and_return(24 * 60 * 60)
          @user1 = create(:user, email_throttling_delay: 24 * 60 * 60)
          @user2 = create(:user)
          @profile1 = create(:notification_profile, users: [@user1, @user2], maximum_email_throttling_delay: 60 * 60)
          @profile2 = create(:notification_profile, users: [@user1, @user2])
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user2)
          create(:notification, notification_profile: @profile2, user: @user1)
          create(:notification, notification_profile: @profile2, user: @user2)
        end

        it 'returns only users with pending notifications matching the throttling settings for the profile-user-combination' do
          expect(@profile1.recipients_with_pending(throttle: 60 * 60)).to contain(@user1, count: 1)
          expect(@profile1.recipients_with_pending(throttle: 60 * 60)).to contain(@user2, count: 1)

          expect(@profile1.recipients_with_pending(throttle: 24 * 60 * 60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 24 * 60 * 60)).not_to include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 60 * 60)).to_not include(@user1)
          expect(@profile2.recipients_with_pending(throttle: 60 * 60)).to_not include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 24 * 60 * 60)).to contain(@user1, count: 1)
          expect(@profile2.recipients_with_pending(throttle: 24 * 60 * 60)).to contain(@user2, count: 1)
        end
      end

      describe 'user throttling delay is minimum' do
        before(:each) do
          allow(Rails.application.config).to receive(:maximum_email_throttling_delay).and_return(24 * 60 * 60)
          @user1 = create(:user, email_throttling_delay: 60 * 60)
          @user2 = create(:user)
          @profile1 = create(:notification_profile, users: [@user1, @user2])
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user2)
        end

        it 'returns only users with pending notifications matching the throttling settings for the profile-user-combination' do
          expect(@profile1.recipients_with_pending(throttle: 60 * 60)).to contain(@user1, count: 1)
          expect(@profile1.recipients_with_pending(throttle: 60 * 60)).not_to include(@user2)

          expect(@profile1.recipients_with_pending(throttle: 24 * 60 * 60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 24 * 60 * 60)).to contain(@user2, count: 1)
        end
      end

      describe 'system maximum throttling delay is minimum' do
        before(:each) do
          allow(Rails.application.config).to receive(:maximum_email_throttling_delay).and_return(60 * 60)
          @user1 = create(:user, email_throttling_delay: 7 * 24 * 60 * 60)
          @user2 = create(:user)
          @profile1 = create(:notification_profile, users: [@user1])
          @profile2 = create(:notification_profile, users: [@user1, @user2], maximum_email_throttling_delay: 24 * 60 * 60)
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user1)
          create(:notification, notification_profile: @profile1, user: @user2)
          create(:notification, notification_profile: @profile2, user: @user1)
          create(:notification, notification_profile: @profile2, user: @user2)
        end

        it 'returns only users with pending notifications matching the throttling settings for the profile-user-combination' do
          expect(@profile1.recipients_with_pending(throttle: 60 * 60)).to contain(@user1, count: 1)
          expect(@profile1.recipients_with_pending(throttle: 60 * 60)).to contain(@user2, count: 1)

          expect(@profile1.recipients_with_pending(throttle: 24 * 60 * 60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 24 * 60 * 60)).not_to include(@user2)

          expect(@profile1.recipients_with_pending(throttle: 7 * 24 * 60 * 60)).not_to include(@user1)
          expect(@profile1.recipients_with_pending(throttle: 7 * 24 * 60 * 60)).not_to include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 60 * 60)).to contain(@user1, count: 1)
          expect(@profile2.recipients_with_pending(throttle: 60 * 60)).to contain(@user2, count: 1)

          expect(@profile2.recipients_with_pending(throttle: 24 * 60 * 60)).not_to include(@user1)
          expect(@profile2.recipients_with_pending(throttle: 24 * 60 * 60)).not_to include(@user2)

          expect(@profile2.recipients_with_pending(throttle: 7 * 24 * 60 * 60)).not_to include(@user1)
          expect(@profile2.recipients_with_pending(throttle: 7 * 24 * 60 * 60)).not_to include(@user2)
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
      t.json :required_series
      t.references :extra_model
    end
    model do
      include NotificationFilter

      has_paper_trail class_name: 'Version'

      has_many :multi_models
      belongs_to :extra_model

      notification_attribute_filter(:required_series, :changes_tqc_state) do |old, new|
        return false if new.blank? || !new.is_a?(Hash)
        new.map do |name, _|
          next if old.blank? || old[name].blank? || !old[name].is_a?(Hash) || !new[name].is_a?(Hash)
          old[name]['tqc_state'] != new[name]['tqc_state']
        end.any?
      end
    end
  end

  describe '::triggered_by' do
    before(:each) do
      @p0 = create(:notification_profile, triggering_actions: %w[create update destroy], triggering_resource: 'TestModel', is_enabled: false)

      @p1 = create(:notification_profile, triggering_actions: %w[create update destroy], triggering_resource: 'TestModel')
      @p2 = create(:notification_profile, triggering_actions: %w[create], triggering_resource: 'TestModel')
      @p3 = create(:notification_profile, triggering_actions: %w[update], triggering_resource: 'TestModel')
      @p4 = create(:notification_profile, triggering_actions: %w[destroy], triggering_resource: 'TestModel')
      @p5 = create(:notification_profile, triggering_actions: %w[create update], triggering_resource: 'TestModel')

      @pe0 = create(:notification_profile, triggering_actions: %w[create update destroy], triggering_resource: 'ExtraModel', is_enabled: false)

      @pe1 = create(:notification_profile, triggering_actions: %w[create update destroy], triggering_resource: 'ExtraModel')
      @pe2 = create(:notification_profile, triggering_actions: %w[create], triggering_resource: 'ExtraModel')
      @pe3 = create(:notification_profile, triggering_actions: %w[update], triggering_resource: 'ExtraModel')
      @pe4 = create(:notification_profile, triggering_actions: %w[destroy], triggering_resource: 'ExtraModel')
      @pe5 = create(:notification_profile, triggering_actions: %w[create update], triggering_resource: 'ExtraModel')

      @record = TestModel.create
      @record2 = ExtraModel.create
    end

    it 'is defined' do
      expect(NotificationProfile).to respond_to('triggered_by')
    end

    describe ':create TestModel' do
      before(:each) do
        @profiles = NotificationProfile.triggered_by(:create, 'TestModel', @record)
      end
      it 'does not return disabled profiles triggered for all actions' do
        expect(@profiles).not_to include(@p0)
        expect(@profiles).not_to include(@pe0)
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
      it 'does return profiles triggered for :create or :update' do
        expect(@profiles).to include(@p5)
      end
      it 'does not return any profile triggered for ExtraModel' do
        expect(@profiles).not_to include(@pe1)
        expect(@profiles).not_to include(@pe2)
        expect(@profiles).not_to include(@pe3)
        expect(@profiles).not_to include(@pe4)
        expect(@profiles).not_to include(@pe5)
      end

      include_examples 'filters changes', triggering_actions: %w[create update destroy], event_action: :create
      include_examples 'filters changes', triggering_actions: %w[create], event_action: :create
    end

    describe ':update TestModel' do
      before(:each) do
        @profiles = NotificationProfile.triggered_by(:update, 'TestModel', @record)
      end
      it 'does not return disabled profiles triggered for all actions' do
        expect(@profiles).not_to include(@p0)
        expect(@profiles).not_to include(@pe0)
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
      it 'does return profiles triggered for :create or :update' do
        expect(@profiles).to include(@p5)
      end
      it 'does not return any profile triggered for ExtraModel' do
        expect(@profiles).not_to include(@pe1)
        expect(@profiles).not_to include(@pe2)
        expect(@profiles).not_to include(@pe3)
        expect(@profiles).not_to include(@pe4)
      end

      include_examples 'filters changes', triggering_actions: %w[create update destroy], event_action: :update
      include_examples 'filters changes', triggering_actions: %w[update], event_action: :update
    end

    describe ':destroy TestModel' do
      before(:each) do
        @profiles = NotificationProfile.triggered_by(:destroy, 'TestModel', @record)
      end
      it 'does not return disabled profiles triggered for all actions' do
        expect(@profiles).not_to include(@p0)
        expect(@profiles).not_to include(@pe0)
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
      it 'does not return profiles triggered for :create or :update' do
        expect(@profiles).not_to include(@p5)
      end
      it 'does not return any profile triggered for ExtraModel' do
        expect(@profiles).not_to include(@pe1)
        expect(@profiles).not_to include(@pe2)
        expect(@profiles).not_to include(@pe3)
        expect(@profiles).not_to include(@pe4)
      end

      include_examples 'filters changes', triggering_actions: %w[create update destroy], event_action: :destroy
      include_examples 'filters changes', triggering_actions: %w[destroy], event_action: :destroy
    end

    describe ':update custom filter attribute', focus: true do
      before(:each) do
        @record = TestModel.create(required_series: { 'abc' => { 'tqc_state' => 0 } })
        @record.required_series = { 'abc' => { 'tqc_state' => 1 } }
        @record.save!
        @pcustom = create(:notification_profile, title: 'Filtered Profile', triggering_actions: %w[update], triggering_resource: 'TestModel', filters: [[{ 'required_series' => { 'changes_tqc_state' => true } }]], is_enabled: true)
      end

      before(:each) do
        @profiles = NotificationProfile.triggered_by(:update, 'TestModel', @record, @record.versions.last.object_changes)
      end

      it 'matches custom filter' do
        expect(@profiles).to include(@pcustom)
      end
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
    end

    it 'creates notification for system actions' do
      ::PaperTrail.whodunnit = nil
      @record = TestModel.create(foobar: 'foo')
      expect do
        @profile1.trigger(@record.versions.last)
      end.to change(Notification, :count).by(2)
      expect(Notification.where(user: @user1)).to exist
      expect(Notification.where(user: @user2)).to exist
      expect(Notification.where(user: @user1).first.triggering_action).to eq('create')
      expect(Notification.where(user: @user2).first.triggering_action).to eq('create')
    end

    describe 'with excluding triggering user' do
      before(:each) do
        @profile1.filter_triggering_user = 'exclude'
        @profile1.save!

        ::PaperTrail.whodunnit = @user2.id
        @record = TestModel.create(foobar: 'foo')
      end

      it 'creates notification for other users actions' do
        expect do
          @profile1.trigger(@record.versions.last)
        end.to change(Notification, :count).by(1)
        expect(Notification.where(user: @user1)).to exist
      end

      it 'does not create a notification for my own action' do
        expect do
          @profile1.trigger(@record.versions.last)
        end.to change(Notification, :count).by(1)
        expect(Notification.where(user: @user2)).not_to exist
      end
    end

    describe 'with including triggering user' do
      before(:each) do
        @profile1.filter_triggering_user = 'include'
        @profile1.save!

        ::PaperTrail.whodunnit = @user2.id
        @record = TestModel.create(foobar: 'foo')
      end

      it 'creates notification for other users actions' do
        expect do
          @profile1.trigger(@record.versions.last)
        end.to change(Notification, :count).by(2)
        expect(Notification.where(user: @user1)).to exist
      end

      it 'creates a notification for my own action' do
        expect do
          @profile1.trigger(@record.versions.last)
        end.to change(Notification, :count).by(2)
        expect(Notification.where(user: @user2)).to exist
      end
    end

    describe 'only filtering triggering user' do
      before(:each) do
        @profile1.filter_triggering_user = 'only'
        @profile1.save!

        ::PaperTrail.whodunnit = @user2.id
        @record = TestModel.create(foobar: 'foo')
      end

      it 'does not create notification for other users actions' do
        expect do
          @profile1.trigger(@record.versions.last)
        end.to change(Notification, :count).by(1)
        expect(Notification.where(user: @user1)).not_to exist
      end

      it 'creates a notification for my own action' do
        expect do
          @profile1.trigger(@record.versions.last)
        end.to change(Notification, :count).by(1)
        expect(Notification.where(user: @user2)).to exist
      end
    end

    it 'creates notification only for authorized users' do
      ::PaperTrail.whodunnit = nil
      @record = TestModel.create(foobar: 'foo')
      allow_any_instance_of(Ability).to receive(:can?) { |ability, _activity, _subject|
        ability.current_user == @user1
      }
      expect do
        @profile2.trigger(@record.versions.last)
      end.to change(Notification, :count).by(1)
      expect(Notification.where(user: @user1)).to exist
      expect(Notification.where(user: @user2)).not_to exist
    end
  end
end
