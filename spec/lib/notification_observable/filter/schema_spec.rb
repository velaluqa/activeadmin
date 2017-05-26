RSpec.describe NotificationObservable::Filter::Schema do
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
      t.datetime :foobar, null: false
      t.text :foobaz, null: true
      t.references :sub_model
    end
    model do
      belongs_to :sub_model
    end
  end

  describe '#schema' do
    before(:each) do
      @schema = NotificationObservable::Filter::Schema.new(TestModel).schema
    end

    it 'defines the basic filter schema to the root model' do
      model = NotificationObservable::Filter::Schema::Model.new(TestModel)
      expect(@schema.dig2('items', 'items')).to include(model.definition.deep_stringify_keys)
    end

    it 'has model definitions for all nested relations' do
      sub_model = NotificationObservable::Filter::Schema::Model.new(SubModel, filters: %i[equality relations], ignore_relations: [TestModel], is_relation: true)
      expect(@schema.dig2('definitions'))
        .to include('model_sub_model' => sub_model.definition.deep_stringify_keys)

      sub_sub_model = NotificationObservable::Filter::Schema::Model.new(SubSubModel, filters: %i[equality relations], ignore_relations: [TestModel, SubModel], is_relation: true)
      expect(@schema.dig2('definitions'))
        .to include('model_sub_sub_model' => sub_sub_model.definition.deep_stringify_keys)
    end
  end

  describe 'json-validator' do
    before(:each) do
      @schema = NotificationObservable::Filter::Schema.new(TestModel).schema
    end

    after(:each) do
      expect(JSON::Validator.validate(@schema, @data)).to be_truthy
    end

    it 'validates foo.equal: "bar"' do
      @data = [
        [
          {
            'foo' => {
              'equal' => 'bar'
            }
          }
        ]
      ]
    end

    it 'validates foo.notEqual: "bar"' do
      @data = [
        [
          {
            'foo' => {
              'notEqual' => 'bar'
            }
          }
        ]
      ]
    end

    it 'validates foo.changes: true' do
      @data = [
        [
          {
            'foo' => {
              'changes' => true
            }
          }
        ]
      ]
    end

    it 'validates foo.changes: false' do
      @data = [
        [
          {
            'foo' => {
              'changes' => false
            }
          }
        ]
      ]
    end

    it 'validates foo.changes[any => "bar"]' do
      @data = [
        [
          {
            'foo' => {
              'changes' => {
                'to' => 'bar'
              }
            }
          }
        ]
      ]
    end

    it 'validates foo.changes["bar" => any]' do
      @data = [
        [
          {
            'foo' => {
              'changes' => {
                'from' => 'bar'
              }
            }
          }
        ]
      ]
    end

    it 'validates foo.changes["bar" => "foo"]' do
      @data = [
        [
          {
            'foo' => {
              'changes' => {
                'from' => 'bar',
                'to' => 'foo'
              }
            }
          }
        ]
      ]
    end

    it 'validates foo.changes["bar" => nil]' do
      @data = [
        [
          {
            'foo' => {
              'changes' => {
                'from' => 'bar',
                'to' => nil
              }
            }
          }
        ]
      ]
    end

    it 'validates sub_model: true' do
      @data = [
        [
          {
            'sub_model' => true
          }
        ]
      ]
    end

    it 'validates sub_model: false' do
      @data = [
        [
          {
            'sub_model' => false
          }
        ]
      ]
    end

    it 'validates sub_model.bar.equal: 5' do
      @data = [
        [
          {
            'sub_model' => {
              'bar' => {
                'equal' => 5
              }
            }
          }
        ]
      ]
    end

    it 'validates sub_model.sub_sub_models.foobaz.equal: "foobar"' do
      @data = [
        [
          {
            'sub_model' => {
              'sub_sub_models' => {
                'foobaz' => {
                  'equal' => 'foobar'
                }
              }
            }
          }
        ]
      ]
    end

    it 'validates sub_model.sub_sub_models: true' do
      @data = [
        [
          {
            'sub_model' => {
              'sub_sub_models' => true
            }
          }
        ]
      ]
    end

    it 'validates sub_model.sub_sub_models: false' do
      @data = [
        [
          {
            'sub_model' => {
              'sub_sub_models' => false
            }
          }
        ]
      ]
    end
  end
end
