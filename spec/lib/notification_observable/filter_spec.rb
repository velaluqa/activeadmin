RSpec.describe NotificationObservable::Filter do
  with_model :TestModel do
    table do |t|
      t.string :foo
      t.string :fu
      t.references :sub_model
    end
    model do
      belongs_to :sub_model
    end
  end

  with_model :SubModel do
    table do |t|
      t.integer :bar
    end
    model do
      has_one :test_model
      has_many :sub_sub_models
    end
  end

  with_model :SubSubModel do
    table do |t|
      t.string :foobar
      t.references :sub_model
    end
    model do
      belongs_to :sub_model
    end
  end

  describe '#match?' do
    before(:each) do
      @record1 = TestModel.create(foo: 'bar')
      @record2 = TestModel.create(foo: 'baz')
      @record3 = TestModel.create(foo: 'buz')
    end

    it 'matches for empty filters' do
      @filter = NotificationObservable::Filter.new([])
      expect(@filter.match?(@record1, foo: [nil, 'bar'], fu: [nil, 'baz'])).to be_truthy
      expect(@filter.match?(@record2, foo: [nil, 'baz'])).to be_truthy
      expect(@filter.match?(@record3, foo: [nil, 'buz'])).to be_truthy
    end

    it 'matches single condition' do
      @filter = NotificationObservable::Filter.new(
        [
          [
            {
              foo: {
                changes: {
                  to: 'bar'
                }
              }
            }
          ]
        ]
      )
      @record = TestModel.create(foo: 'bar')
      expect(@filter.match?(@record, foo: [nil, 'bar'])).to be_truthy
    end

    it 'matches or\'ed conditions' do
      @filter = NotificationObservable::Filter.new(
        [
          [
            {
              foo: {
                changes: {
                  to: 'baz'
                }
              }
            }
          ],
          [
            {
              foo: {
                changes: {
                  to: 'bar'
                }
              }
            }
          ]
        ]
      )
      expect(@filter.match?(@record1, foo: [nil, 'bar'], fu: [nil, 'baz'])).to be_truthy
      expect(@filter.match?(@record2, foo: [nil, 'baz'])).to be_truthy
      expect(@filter.match?(@record3, foo: [nil, 'buz'])).to be_falsy
    end
  end

  describe '#match_condition' do
    describe 'given attribute condition' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
        @model = TestModel.create(foo: 'office')
        @changes = { foo: %w(foo bar) }
      end

      it 'matches attribute' do
        expect(@filter).to receive(:match_attribute)
                            .once
                            .with('foo', { equal: 'office' }, @model, @changes)
                            .and_return(true)
        @filter.match_condition({ foo: { equal: 'office' } }, @model, @changes)
      end
    end

    describe 'given relation condition' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
        @model = TestModel.create(foo: 'office')
        @changes = { foo: %w(foo bar) }
      end

      it 'matches relation' do
        expect(@filter).to receive(:match_relation)
                            .once
                            .with(@model, :sub_model, { bar: { equal: 5 } })
                            .and_return(true)
        @filter.match_condition({ sub_model: { bar: { equal: 5 } } }, @model, @changes)
      end
    end
  end

  describe '#match_attribute' do
    describe 'matching foo' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
        @model = TestModel.create(foo: 'office')
        @changes = { 'foo' => %w(home office) }
      end

      it 'handles `equal`' do
        expect(@filter.match_attribute('foo', { equal: 'office' }, @model, @changes)).to be_truthy
        expect(@filter.match_attribute('foo', { equal: 'home' }, @model, @changes)).to be_falsy
      end

      it 'handles change' do
        expect(@filter.match_attribute('foo', { changes: { from: 'home' } }, @model, @changes)).to be_truthy
        expect(@filter.match_attribute('foo', { changes: { from: 'office' } }, @model, @changes)).to be_falsy
      end
    end
  end

  describe '#match_relation' do
    describe 'for existence' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
        @model = TestModel.create(foo: 'office')
        @sub_model = SubModel.create(bar: 15, test_model: @model)
        @sub_sub_model = SubSubModel.create(foobar: 'much_more', sub_model: @sub_model)
        @model2 = TestModel.create(foo: 'office')
        @sub_model = SubModel.create(bar: 15, test_model: @model2)
        @model3 = TestModel.create(foo: 'office')
      end

      it 'matches existence of sub_model' do
        expect(@filter.match_relation(@model, :sub_model, true)).to be_truthy
        expect(@filter.match_relation(@model, :sub_model, false)).to be_falsy
        expect(@filter.match_relation(@model2, :sub_model, true)).to be_truthy
        expect(@filter.match_relation(@model2, :sub_model, false)).to be_falsy
        expect(@filter.match_relation(@model3, :sub_model, true)).to be_falsy
        expect(@filter.match_relation(@model3, :sub_model, false)).to be_truthy
      end

      it 'matches existence of sub_model.sub_sub_model' do
        expect(@filter.match_relation(@model, :sub_model, { sub_sub_models: true})).to be_truthy
        expect(@filter.match_relation(@model, :sub_model, { sub_sub_models: false})).to be_falsy
        expect(@filter.match_relation(@model2, :sub_model, { sub_sub_models: true})).to be_falsy
        expect(@filter.match_relation(@model2, :sub_model, { sub_sub_models: false})).to be_truthy
        expect(@filter.match_relation(@model3, :sub_model, { sub_sub_models: true})).to be_falsy
        expect(@filter.match_relation(@model3, :sub_model, { sub_sub_models: false})).to be_truthy
      end
    end

    describe 'for attribute equality'  do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
        @model = TestModel.create(foo: 'office')
        @sub_model = SubModel.create(bar: 15, test_model: @model)
        @sub_sub_model = SubSubModel.create(foobar: 'much_more', sub_model: @sub_model)
      end

      it 'matches equality of sub_model.bar' do
        expect(@filter.match_relation(@model, :sub_model, { bar: { equal: 15 }})).to be_truthy
        expect(@filter.match_relation(@model, :sub_model, { bar: { equal: 20 }})).to be_falsy
      end

      it 'matches equality of sub_model.sub_sub_model.foobar' do
        expect(@filter.match_relation(@model, :sub_model, { sub_sub_models: { foobar: { equal: 'much_more' }}})).to be_truthy
        expect(@filter.match_relation(@model, :sub_model, { sub_sub_models: { foobar: { equal: 'nothing' }}})).to be_falsy
      end

      describe 'for attribute non-equality'  do
        before(:each) do
          @filter = NotificationObservable::Filter.new({})
          @model = TestModel.create(foo: 'office')
          @sub_model = SubModel.create(bar: 15, test_model: @model)
          @sub_sub_model = SubSubModel.create(foobar: 'much_more', sub_model: @sub_model)
        end

        it 'matches equality of sub_model.bar' do
          expect(@filter.match_relation(@model, :sub_model, { bar: { notEqual: 15 }})).to be_falsy
          expect(@filter.match_relation(@model, :sub_model, { bar: { notEqual: 20 }})).to be_truthy
        end

        it 'matches equality of sub_model.sub_sub_model.foobar' do
          expect(@filter.match_relation(@model, :sub_model, { sub_sub_models: { foobar: { notEqual: 'much_more' }}})).to be_falsy
          expect(@filter.match_relation(@model, :sub_model, { sub_sub_models: { foobar: { notEqual: 'nothing' }}})).to be_truthy
        end
      end
    end
  end

  describe '#relation_joins' do
    before(:each) do
      @filter = NotificationObservable::Filter.new({})
    end

    it 'returns the correct joins structure' do
      expect(@filter.relation_joins(:sub_model, {:sub_sub_models => {foobar: {equal: 'something'}}})).to eq(sub_model: :sub_sub_models)
      expect(@filter.relation_joins(:sub_model, {foo: {equal: 'something'}})).to eq(:sub_model)
    end
  end

  describe '#relation_condition' do
    before(:each) do
      @filter = NotificationObservable::Filter.new({})
    end

    describe 'checking for existance' do
      it 'returns the correct conditions' do
        condition = @filter.relation_condition(TestModel, :sub_model, true)
        expect(condition[0]).to match(/sub_models/)
        expect(condition[1]).to be_nil
        expect(condition[2]).to be_truthy
        expect(condition[3]).to be_nil
      end

      it 'returns the correct conditions for related models' do
        condition = @filter.relation_condition(TestModel, :sub_model, {:sub_sub_models => true})
        expect(condition[0]).to match(/sub_sub_models/)
        expect(condition[1]).to be_nil
        expect(condition[2]).to be_truthy
        expect(condition[3]).to be_nil
      end
    end

    describe 'checking for non-existance' do
      it 'returns the correct conditions' do
        condition = @filter.relation_condition(TestModel, :sub_model, false)
        expect(condition[0]).to match(/sub_models/)
        expect(condition[1]).to be_nil
        expect(condition[2]).to be_falsy
        expect(condition[3]).to be_nil
      end

      it 'returns the correct conditions for related models' do
        condition = @filter.relation_condition(TestModel, :sub_model, {:sub_sub_models => false})
        expect(condition[0]).to match('sub_sub_models')
        expect(condition[1]).to be_nil
        expect(condition[2]).to be_falsy
        expect(condition[3]).to be_nil
      end
    end

    describe 'checking for equality' do
      it 'returns the correct conditions for value match' do
        condition = @filter.relation_condition(TestModel, :sub_model, {foo: {equal: 'something'}})
        expect(condition[0]).to match(/sub_model/)
        expect(condition[1]).to eq(:foo)
        expect(condition[2]).to eq('something')
        expect(condition[3]).to be_truthy
      end

      it 'returns the correct conditions for related models value match' do
        condition = @filter.relation_condition(TestModel, :sub_model, {:sub_sub_models => {foobar: {equal: 'something'}}})
        expect(condition[0]).to match(/sub_sub_models/)
        expect(condition[1]).to eq(:foobar)
        expect(condition[2]).to eq('something')
        expect(condition[3]).to be_truthy
      end
    end

    describe 'checking for non-equality' do
      it 'returns the correct conditions for value match' do
        condition = @filter.relation_condition(TestModel, :sub_model, {foo: {notEqual: 'something'}})
        expect(condition[0]).to match(/sub_model/)
        expect(condition[1]).to eq(:foo)
        expect(condition[2]).to eq('something')
        expect(condition[3]).to be_falsy
      end

      it 'returns the correct conditions for related models value match' do
        condition = @filter.relation_condition(TestModel, :sub_model, {:sub_sub_models => {foobar: {notEqual: 'something'}}})
        expect(condition[0]).to match(/sub_sub_models/)
        expect(condition[1]).to eq(:foobar)
        expect(condition[2]).to eq('something')
        expect(condition[3]).to be_falsy
      end
    end
  end

  describe '#match_change for filter' do
    describe 'foo[=>"home"]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { to: 'home' }, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_truthy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', { to: 'home' }, { 'foo' => nil }, { 'foo' => 'home' })).to be_truthy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', { to: 'home' }, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_falsy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', { to: 'home' }, { 'foo' => 'office' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', { to: 'home' }, { 'foo' => 'gym' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { to: 'home' }, { 'foo' => 'home' }, { 'foo' => "home" })).to be_falsy
      end
    end
    describe 'foo[nil=>"home"]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: nil, to: 'home' }, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: nil, to: 'home' }, { 'foo' => nil }, { 'foo' => 'home' })).to be_truthy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', { from: nil, to: 'home' }, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_falsy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: nil, to: 'home' }, { 'foo' => 'office' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: nil, to: 'home' }, { 'foo' => 'gym' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: nil, to: 'home' }, { 'foo' => 'home' }, { 'foo' => "home" })).to be_falsy
      end
    end
    describe 'foo["office"=>"home"]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: 'home' }, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_truthy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: 'home' }, { 'foo' => nil }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: 'home' }, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_falsy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: 'home' }, { 'foo' => 'office' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: 'home' }, { 'foo' => 'gym' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: 'home' }, { 'foo' => 'home' }, { 'foo' => "home" })).to be_falsy
      end
    end
    describe 'foo["office"=>]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office' }, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_truthy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office' }, { 'foo' => nil }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office' }, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_truthy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: 'office' }, { 'foo' => 'office' }, { 'foo' => nil })).to be_truthy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: 'office' }, { 'foo' => 'gym' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office' }, { 'foo' => 'home' }, { 'foo' => "home" })).to be_falsy
      end
    end
    describe 'foo["office"=>nil]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: nil }, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: nil }, { 'foo' => nil }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: nil }, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_falsy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: nil }, { 'foo' => 'office' }, { 'foo' => nil })).to be_truthy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: nil }, { 'foo' => 'gym' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { from: 'office', to: nil }, { 'foo' => 'home' }, { 'foo' => "home" })).to be_falsy
      end
    end
    describe 'foo[=>nil]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { to: nil }, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', { to: nil }, { 'foo' => nil }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', { to: nil }, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_falsy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', { to: nil }, { 'foo' => 'office' }, { 'foo' => nil })).to be_truthy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', { to: nil }, { 'foo' => 'gym' }, { 'foo' => nil })).to be_truthy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', { to: nil }, { 'foo' => 'home' }, { 'foo' => "home" })).to be_falsy
      end
    end
    describe 'foo[change]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', true, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_truthy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', true, { 'foo' => nil }, { 'foo' => 'home' })).to be_truthy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', true, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_truthy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', true, { 'foo' => 'office' }, { 'foo' => nil })).to be_truthy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', true, { 'foo' => 'gym' }, { 'foo' => nil })).to be_truthy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', true, { 'foo' => 'home' }, { 'foo' => "home" })).to be_falsy
      end
    end
    describe 'foo[nochange]' do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
      end

      it 'matches foo["office"=>"home"] accordingly' do
        expect(@filter.match_change('foo', false, { 'foo' => 'office' }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo[nil=>"home"] accordingly' do
        expect(@filter.match_change('foo', false, { 'foo' => nil }, { 'foo' => 'home' })).to be_falsy
      end
      it 'matches foo["office"=>"gym"] accordingly' do
        expect(@filter.match_change('foo', false, { 'foo' => 'office' }, { 'foo' => 'gym' })).to be_falsy
      end
      it 'matches foo["office"=>nil] accordingly' do
        expect(@filter.match_change('foo', false, { 'foo' => 'office' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["gym"=>nil] accordingly' do
        expect(@filter.match_change('foo', false, { 'foo' => 'gym' }, { 'foo' => nil })).to be_falsy
      end
      it 'matches foo["home"=>"home"] accordingly' do
        expect(@filter.match_change('foo', false, { 'foo' => 'home' }, { 'foo' => "home" })).to be_truthy
      end
    end
  end
end
