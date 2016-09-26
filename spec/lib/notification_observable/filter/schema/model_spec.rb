RSpec.describe NotificationObservable::Filter::Schema::Model do
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

  describe '#definition' do
    describe 'for is_relation: true' do
      before(:each) do
        @model = NotificationObservable::Filter::Schema::Model.new(TestModel, is_relation: true)
        @schema = @model.definition
      end

      it 'validates existance' do
        expect(@schema[:oneOf]).to include(include(title: 'Record exists?', type: 'boolean'))
      end
    end

    describe 'without options' do
      before(:each) do
        @model = NotificationObservable::Filter::Schema::Model.new(TestModel)
        @schema = @model.definition
      end

      it 'returns schema for root attributes' do
        expect(@schema).to include(:oneOf)
        expect(@schema[:oneOf]).to include(include(title: 'id'))
        expect(@schema[:oneOf]).to include(include(title: 'foo'))
      end

      it 'returns schema for related models foreign keys' do
        expect(@schema[:oneOf]).to include(include(title: 'sub_model_id'))
      end

      it 'returns schema with references for related models' do
        expect(@schema[:oneOf]).to include(include(title: 'Related SubModel'))

        sub_model = @schema.dig2(:oneOf, { title: 'Related SubModel' }, :properties, 'sub_model')
        expect(sub_model).to include('$ref' => '#/definitions/model_sub_model')
      end

      it 'skips relations if already in path' do
        @model = NotificationObservable::Filter::Schema::Model.new(SubModel, path: [TestModel])
        expect(@model.definition[:oneOf]).not_to include(nil)
      end
    end
  end
end
