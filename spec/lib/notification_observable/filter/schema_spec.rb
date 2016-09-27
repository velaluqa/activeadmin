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
      t.datetime :foobar, null:false
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
      sub_model = NotificationObservable::Filter::Schema::Model.new(SubModel, filters: [:equality, :relations], ignore_relations: [TestModel], is_relation: true)
      expect(@schema.dig2('definitions'))
        .to include('model_sub_model' => sub_model.definition.deep_stringify_keys)

      sub_sub_model = NotificationObservable::Filter::Schema::Model.new(SubSubModel, filters: [:equality, :relations], ignore_relations: [TestModel, SubModel], is_relation: true)
      expect(@schema.dig2('definitions'))
        .to include('model_sub_sub_model' => sub_sub_model.definition.deep_stringify_keys)
    end
  end
end
