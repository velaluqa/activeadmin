RSpec.shared_examples "triggering changes" do |options|
  triggering_action = options[:triggering_action].andand.to_s || 'all'
  event_action = options[:event_action].andand.to_sym || :update

  context 'changing' do
    before(:each) do
      @pc1 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          to: 'baz'
                        }
                      }
                    ])
      @pc2 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          to: 'bar'
                        }
                      }
                    ])
      @pc3 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          from: 'foo',
                          to: 'baz'
                        }
                      }
                    ])
      @pc4 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          from: 'foo',
                          to: 'bar'
                        }
                      }
                    ])
      @pc5 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          from: 'fu',
                          to: 'baz'
                        }
                      }
                    ])
      @pc6 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          from: 'fu',
                          to: 'bar'
                        }
                      }
                    ])
      @pc7 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          from: 'foo'
                        }
                      }
                    ])
      @pc8 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          from: 'fu'
                        }
                      }
                    ])
      @pc9 = create(:notification_profile,
                    triggering_action: triggering_action,
                    triggering_resource: 'TestModel',
                    triggering_changes: [
                      {
                        foobar: {
                          from: 'foo',
                          to: nil
                        }
                      }
                    ])
      @pc10 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     triggering_changes: [
                       {
                         foobar: {
                           from: nil,
                           to: 'bar'
                         }
                       }
                     ])
      @pc11 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     triggering_changes: [
                       {
                         foobar: {
                           to: 'bar'
                         },
                         foobaz: {
                           from: 'bar',
                           to: 'buz'
                         }
                       }
                     ])
      @pc12 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     triggering_changes: [
                       {
                         foobar: {
                           to: 'baz'
                         }
                       }, {
                         foobar: {
                           to: 'bar'
                         }
                       }
                     ])
      @pc13 = create(:notification_profile,
                     triggering_action: triggering_action,
                     triggering_resource: 'TestModel',
                     triggering_changes: [
                       {
                         foobar: {
                           to: 'baz'
                         },
                         foobaz: {
                           from: 'bar',
                           to: 'buz'
                         }
                       }, {
                         foobar: {
                           to: 'bar'
                         }
                       }
                     ])

      @record = TestModel.create
    end

    describe 'foobar(nil => "bar")' do
      before(:each) do
        expect(@record)
          .to receive(:changes)
          .at_least(1)
          .and_return(
            foobar: [nil, 'bar'],
            foobaz: [nil, 'buz']
          )
        @triggered_profiles = NotificationProfile.triggered_by(event_action, @record)
      end

      it 'does not return profile triggered by attribute `foobar` change from any value to `baz`' do
        expect(@triggered_profiles).not_to include(@pc1)
      end
      it 'returns profile triggered by attribute `foobar` change from any value to `bar`' do
        expect(@triggered_profiles).to include(@pc2)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to `baz`' do
        expect(@triggered_profiles).not_to include(@pc3)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to `bar`' do
        expect(@triggered_profiles).not_to include(@pc4)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to `baz`' do
        expect(@triggered_profiles).not_to include(@pc5)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to `bar`' do
        expect(@triggered_profiles).not_to include(@pc6)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to any value' do
        expect(@triggered_profiles).not_to include(@pc7)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to any value' do
        expect(@triggered_profiles).not_to include(@pc8)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to nil' do
        expect(@triggered_profiles).not_to include(@pc9)
      end
      it 'returns profile triggered by attribute `foobar` change from nil to `bar`' do
        expect(@triggered_profiles).to include(@pc10)
      end
      it 'does not return profile triggered by foobar(*any* => "bar") and foobaz("bar" => *any*)' do
        expect(@triggered_profiles).not_to include(@pc11)
      end
      it 'does not return profile triggered by foobar(*any* => "baz") OR foobar(*any* => "bar")' do
        expect(@triggered_profiles).to include(@pc12)
      end
      it 'does not return profile triggered by (foobar(*any* => "baz") AND foobaz("bar" => "buz")) OR foobar(*any* => "bar")' do
        expect(@triggered_profiles).to include(@pc13)
      end
    end
    describe 'change from `foo` to `bar`' do
      before(:each) do
        expect(@record)
          .to receive(:changes)
          .at_least(1)
          .and_return(
            foobar: ['foo', 'bar'],
            foobaz: ['bar', 'buz']
          )
        @triggered_profiles = NotificationProfile.triggered_by(event_action, @record)
      end

      it 'does not return profile triggered by attribute `foobar` change from any value to `baz`' do
        expect(@triggered_profiles).not_to include(@pc1)
      end
      it 'returns profile triggered by attribute `foobar` change from any value to `bar`' do
        expect(@triggered_profiles).to include(@pc2)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to `baz`' do
        expect(@triggered_profiles).not_to include(@pc3)
      end
      it 'returns profile triggered by attribute `foobar` change from `foo` to `bar`' do
        expect(@triggered_profiles).to include(@pc4)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to `baz`' do
        expect(@triggered_profiles).not_to include(@pc5)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to `bar`' do
        expect(@triggered_profiles).not_to include(@pc6)
      end
      it 'returns profile triggered by attribute `foobar` change from `foo` to any value' do
        expect(@triggered_profiles).to include(@pc7)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to any value' do
        expect(@triggered_profiles).not_to include(@pc8)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to nil' do
        expect(@triggered_profiles).not_to include(@pc9)
      end
      it 'does not return profile triggered by attribute `foobar` change from nil to `bar`' do
        expect(@triggered_profiles).not_to include(@pc10)
      end
      it 'returns profile triggered by foobar(*any* => "bar") and foobaz("bar" => *any*)' do
        expect(@triggered_profiles).to include(@pc11)
      end
      it 'does not return profile triggered by foobar(*any* => "baz") OR foobar(*any* => "bar")' do
        expect(@triggered_profiles).to include(@pc12)
      end
      it 'does not return profile triggered by (foobar(*any* => "baz") AND foobaz("bar" => "buz")) OR foobar(*any* => "bar")' do
        expect(@triggered_profiles).to include(@pc13)
      end
    end
    describe 'change from `foo` to `nil`' do
      before(:each) do
        expect(@record)
          .to receive(:changes)
          .at_least(1)
          .and_return(foobar: ['foo', nil])
        @triggered_profiles = NotificationProfile.triggered_by(event_action, @record)
      end

      it 'does not return profile triggered by attribute `foobar` change from any value to `baz`' do
        expect(@triggered_profiles).not_to include(@pc1)
      end
      it 'does not return profile triggered by attribute `foobar` change from any value to `bar`' do
        expect(@triggered_profiles).not_to include(@pc2)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to `baz`' do
        expect(@triggered_profiles).not_to include(@pc3)
      end
      it 'does not return profile triggered by attribute `foobar` change from `foo` to `bar`' do
        expect(@triggered_profiles).not_to include(@pc4)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to `baz`' do
        expect(@triggered_profiles).not_to include(@pc5)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to `bar`' do
        expect(@triggered_profiles).not_to include(@pc6)
      end
      it 'returns profile triggered by attribute `foobar` change from `foo` to any value' do
        expect(@triggered_profiles).to include(@pc7)
      end
      it 'does not return profile triggered by attribute `foobar` change from `fu` to any value' do
        expect(@triggered_profiles).not_to include(@pc8)
      end
      it 'returns profile triggered by attribute `foobar` change from `foo` to nil' do
        expect(@triggered_profiles).to include(@pc9)
      end
      it 'does not return profile triggered by attribute `foobar` change from nil to `bar`' do
        expect(@triggered_profiles).not_to include(@pc10)
      end
      it 'does not return profile triggered by foobar(*any* => "bar") and foobaz("bar" => *any*)' do
        expect(@triggered_profiles).not_to include(@pc11)
      end
      it 'does not return profile triggered by foobar(*any* => "baz") OR foobar(*any* => "bar")' do
        expect(@triggered_profiles).not_to include(@pc12)
      end
      it 'does not return profile triggered by (foobar(*any* => "baz") AND foobaz("bar" => "buz")) OR foobar(*any* => "bar")' do
        expect(@triggered_profiles).not_to include(@pc13)
      end
    end
  end
end


RSpec.describe NotificationProfile do
  describe 'model' do
    it { should have_and_belong_to_many(:users) }
    it { should have_and_belong_to_many(:roles) }
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

      @record = TestModel.create
    end

    it 'is defined' do
      expect(NotificationProfile).to respond_to('triggered_by')
    end

    describe ':create TestModel' do
      it 'returns profiles triggered for all actions' do
        triggered_profiles = NotificationProfile.triggered_by(:create, @record)
        expect(triggered_profiles).to include(@p1)
      end
      it 'returns profiles triggered for :create actions' do
        triggered_profiles = NotificationProfile.triggered_by(:create, @record)
        expect(triggered_profiles).to include(@p2)
      end
      it 'does not return profiles triggered for :update' do
        triggered_profiles = NotificationProfile.triggered_by(:create, @record)
        expect(triggered_profiles).not_to include(@p3)
      end
      it 'does not return profiles triggered for :destroy' do
        triggered_profiles = NotificationProfile.triggered_by(:create, @record)
        expect(triggered_profiles).not_to include(@p4)
      end

      include_examples 'triggering changes', triggering_action: 'all', event_action: :create
      include_examples 'triggering changes', triggering_action: 'create', event_action: :create
    end

    describe ':update TestModel' do
      it 'returns profiles triggered for all actions' do
        triggered_profiles = NotificationProfile.triggered_by(:update, @record)
        expect(triggered_profiles).to include(@p1)
      end
      it 'returns profiles triggered for :create actions' do
        triggered_profiles = NotificationProfile.triggered_by(:update, @record)
        expect(triggered_profiles).not_to include(@p2)
      end
      it 'does not return profiles triggered for :update' do
        triggered_profiles = NotificationProfile.triggered_by(:update, @record)
        expect(triggered_profiles).to include(@p3)
      end
      it 'does not return profiles triggered for :destroy' do
        triggered_profiles = NotificationProfile.triggered_by(:update, @record)
        expect(triggered_profiles).not_to include(@p4)
      end

      include_examples 'triggering changes', triggering_action: 'all', event_action: :update
      include_examples 'triggering changes', triggering_action: 'update', event_action: :update
    end

    describe ':destroy TestModel' do
      it 'returns profiles triggered for all actions' do
        triggered_profiles = NotificationProfile.triggered_by(:destroy, @record)
        expect(triggered_profiles).to include(@p1)
      end
      it 'returns profiles triggered for :create actions' do
        triggered_profiles = NotificationProfile.triggered_by(:destroy, @record)
        expect(triggered_profiles).not_to include(@p2)
      end
      it 'does not return profiles triggered for :update' do
        triggered_profiles = NotificationProfile.triggered_by(:destroy, @record)
        expect(triggered_profiles).not_to include(@p3)
      end
      it 'does not return profiles triggered for :destroy' do
        triggered_profiles = NotificationProfile.triggered_by(:destroy, @record)
        expect(triggered_profiles).to include(@p4)
      end

      include_examples 'triggering changes', triggering_action: 'all', event_action: :destroy
      include_examples 'triggering changes', triggering_action: 'destroy', event_action: :destroy
    end
  end

  describe '#filters_match?' do
    before(:each) do
      @p0 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel')
      @p1 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel',
                   filters: [
                     {
                       attributes: {
                         foobar: 'foo',
                         foobaz: nil
                       }
                     }
                   ])
      @p2 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel',
                   filters: [
                     {
                       extra_model: {
                         foo: 'baz'
                       }
                     }
                   ])
      @p3 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel',
                   filters: [
                     {
                       multi_models: true
                     }
                   ])
      @p4 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel',
                   filters: [
                     {
                       multi_models: false
                     }
                   ])
      @p5 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel',
                   filters: [
                     {
                       multi_models: {
                         foo: 'bar'
                       }
                     }
                   ])
      @p6 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel',
                   filters: [
                     {
                       attributes: {
                         foobar: 'foo'
                       },
                       multi_models: {
                         foo: 'bar'
                       }
                     }
                   ])
      @p7 = create(:notification_profile,
                   triggering_action: 'all',
                   triggering_resource: 'TestModel',
                   filters: [
                     {
                       attributes: {
                         foobar: 'foo'
                       }
                     }, {
                       multi_models: {
                         foo: 'bar'
                       }
                     }
                   ])
      @tm = TestModel.create(foobar: 'foo', foobaz: nil)
      @em1 = ExtraModel.create(foo: 'baz')
      @tm_em1 = TestModel.create(foobar: 'foo', extra_model: @em1)
      @em2 = ExtraModel.create(foo: 'bar')
      @tm_em2 = TestModel.create(foobar: 'foo', extra_model: @em2)
      @mm0 = MultiModel.create(foo: nil)
      @mm1 = MultiModel.create(foo: 'fu')
      @mm2 = MultiModel.create(foo: 'bar')
      @mm3 = MultiModel.create(foo: 'bar')
      @tm_mm1 = TestModel.create(foobar: 'foo', multi_models: [@mm0])
      @tm_mm2 = TestModel.create(foobar: 'foo', multi_models: [@mm1])
      @tm_mm3 = TestModel.create(foobar: 'foo', multi_models: [@mm2])
      @tm_mm4 = TestModel.create(foobar: 'bar', multi_models: [@mm3])
    end

    it 'is defined' do
      expect(NotificationProfile.new).to respond_to('filters_match?')
    end

    it 'is always true for profiles without filters' do
      expect(@p0.filters_match?(@tm)).to be_truthy
      expect(@p0.filters_match?(@tm_em1)).to be_truthy
      expect(@p0.filters_match?(@tm_em2)).to be_truthy
    end

    it 'matches resource attributes' do
      expect(@p1.filters_match?(@tm)).to be_truthy
      expect(@p2.filters_match?(@tm)).to be_falsy
      expect(@p6.filters_match?(@tm)).to be_falsy
    end
    it 'matches resource has_one/belongs_to relations' do
      expect(@p2.filters_match?(@tm)).to be_falsy
      expect(@p2.filters_match?(@tm_em1)).to be_truthy
      expect(@p2.filters_match?(@tm_em2)).to be_falsy
    end
    it 'matches resource has_many/habtm relations' do
      expect(@p3.filters_match?(@tm)).to be_falsy
      expect(@p3.filters_match?(@tm_mm1)).to be_truthy
      expect(@p3.filters_match?(@tm_mm2)).to be_truthy
      expect(@p3.filters_match?(@tm_mm3)).to be_truthy
      expect(@p3.filters_match?(@tm_mm4)).to be_truthy

      expect(@p4.filters_match?(@tm)).to be_truthy
      expect(@p4.filters_match?(@tm_mm1)).to be_falsy
      expect(@p4.filters_match?(@tm_mm2)).to be_falsy
      expect(@p4.filters_match?(@tm_mm3)).to be_falsy
      expect(@p4.filters_match?(@tm_mm4)).to be_falsy

      expect(@p5.filters_match?(@tm)).to be_falsy
      expect(@p5.filters_match?(@tm_mm1)).to be_falsy
      expect(@p5.filters_match?(@tm_mm2)).to be_falsy
      expect(@p5.filters_match?(@tm_mm3)).to be_truthy
      expect(@p5.filters_match?(@tm_mm4)).to be_truthy

      expect(@p6.filters_match?(@tm)).to be_falsy
      expect(@p6.filters_match?(@tm_mm1)).to be_falsy
      expect(@p6.filters_match?(@tm_mm2)).to be_falsy
      expect(@p6.filters_match?(@tm_mm3)).to be_truthy
      expect(@p6.filters_match?(@tm_mm4)).to be_falsy

      expect(@p7.filters_match?(@tm)).to be_truthy
      expect(@p7.filters_match?(@tm_mm1)).to be_truthy
      expect(@p7.filters_match?(@tm_mm2)).to be_truthy
      expect(@p7.filters_match?(@tm_mm3)).to be_truthy
      expect(@p7.filters_match?(@tm_mm4)).to be_truthy
    end
  end

  describe '#trigger' do
    it 'is defined' do
      expect(NotificationProfile.new).to respond_to('trigger')
    end
  end
end
