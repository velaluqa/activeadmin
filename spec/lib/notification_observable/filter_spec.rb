RSpec.describe NotificationObservable::Filter do
  with_model :TestModel do
    table do |t|
      t.string :foo
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
                            .with('foo', { matches: 'office' }, @model, @changes)
                            .and_return(true)
        @filter.match_condition({ foo: { matches: 'office' } }, @model, @changes)
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
                            .with(@model, 'sub_model', { bar: { matches: 5 } })
                            .and_return(true)
        @filter.match_condition({ sub_model: { bar: { matches: 5 } } }, @model, @changes)
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

      it 'handles match' do
        expect(@filter.match_attribute('foo', { matches: 'office' }, @model, @changes)).to be_truthy
        expect(@filter.match_attribute('foo', { matches: 'home' }, @model, @changes)).to be_falsy
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
        expect(@filter.match_relation(@model, 'sub_model', true)).to be_truthy
        expect(@filter.match_relation(@model, 'sub_model', false)).to be_falsy
        expect(@filter.match_relation(@model2, 'sub_model', true)).to be_truthy
        expect(@filter.match_relation(@model2, 'sub_model', false)).to be_falsy
        expect(@filter.match_relation(@model3, 'sub_model', true)).to be_falsy
        expect(@filter.match_relation(@model3, 'sub_model', false)).to be_truthy
      end

      it 'matches existence of sub_model.sub_sub_model' do
        expect(@filter.match_relation(@model, 'sub_model', { sub_sub_models: true})).to be_truthy
        expect(@filter.match_relation(@model, 'sub_model', { sub_sub_models: false})).to be_falsy
        expect(@filter.match_relation(@model2, 'sub_model', { sub_sub_models: true})).to be_falsy
        expect(@filter.match_relation(@model2, 'sub_model', { sub_sub_models: false})).to be_truthy
        expect(@filter.match_relation(@model3, 'sub_model', { sub_sub_models: true})).to be_falsy
        expect(@filter.match_relation(@model3, 'sub_model', { sub_sub_models: false})).to be_truthy
      end
    end

    describe 'for attribute match'  do
      before(:each) do
        @filter = NotificationObservable::Filter.new({})
        @model = TestModel.create(foo: 'office')
        @sub_model = SubModel.create(bar: 15, test_model: @model)
        @sub_sub_model = SubSubModel.create(foobar: 'much_more', sub_model: @sub_model)
      end

      it 'matches sub_model.bar' do
        expect(@filter.match_relation(@model, 'sub_model', {bar: { matches: 15}})).to be_truthy
        expect(@filter.match_relation(@model, 'sub_model', {bar: { matches: 20}})).to be_falsy
      end

      it 'matches sub_model.sub_sub_model.foobar' do
        expect(@filter.match_relation(@model, 'sub_model', {sub_sub_models: {foobar: {matches: 'much_more'}}})).to be_truthy
        expect(@filter.match_relation(@model, 'sub_model', {sub_sub_models: {foobar: {matches: 'nothing'}}})).to be_falsy
      end
    end
  end

  describe '#relation_joins' do
    before(:each) do
      @filter = NotificationObservable::Filter.new({})
    end

    it 'returns the correct joins structure' do
      expect(@filter.relation_joins('sub_model', {'sub_sub_model' => {foobar: {matches: 'something'}}})).to eq(sub_model: :sub_sub_model)
      expect(@filter.relation_joins('sub_model', {foo: {matches: 'something'}})).to eq(:sub_model)
    end
  end

  describe '#relation_condition' do
    before(:each) do
      @filter = NotificationObservable::Filter.new({})
    end

    it 'returns the correct conditions for value match' do
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => {foobar: {matches: 'something'}}})[0]).to match(/sub_sub_models/)
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => {foobar: {matches: 'something'}}})[1]).to eq('foobar')
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => {foobar: {matches: 'something'}}})[2]).to eq('something')
    end

    it 'returns the correct conditions for existence' do
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => false})[0]).to match('sub_sub_models')
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => false})[1]).to be_nil
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => false})[2]).to be_falsy
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => true})[0]).to match('sub_sub_models')
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => true})[1]).to be_nil
      expect(@filter.relation_condition(TestModel, 'sub_model', {'sub_sub_model' => true})[2]).to be_truthy
      expect(@filter.relation_condition(TestModel, 'sub_model', true)[0]).to match(/sub_models/)
      expect(@filter.relation_condition(TestModel, 'sub_model', true)[1]).to be_nil
      expect(@filter.relation_condition(TestModel, 'sub_model', true)[2]).to be_truthy
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

  describe '#match_value for filter' do
    before(:each) do
      @filter = NotificationObservable::Filter.new({})
    end

    it 'matches `equal`' do
      expect(@filter.match_value('foo', 'abc', { 'foo' => 'abc' })).to be_truthy
      expect(@filter.match_value('foo', 'def', { 'foo' => 'abc' })).to be_falsy
    end
  end

  describe '#match_relation' do
  end
end
