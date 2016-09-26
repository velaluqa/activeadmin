RSpec.describe NotificationObservable::Filter::Schema::Relation do
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
    describe 'for belongs_to' do
      before(:each) do
        @relation = NotificationObservable::Filter::Schema::Relation.new(TestModel._reflections['sub_model'])
        @schema = @relation.schema
      end

      it 'returns schema for relation' do
        expect(@schema).to include(
                             title: 'Related SubModel',
                             type: 'object',
                             required: ['sub_model'],
                             properties: {
                               'sub_model' => {
                                 '$ref' => '#/definitions/model_sub_model'
                               }
                             }
                           )
      end

      it 'keeps definitions' do
        expect(@relation.definitions).to have_key('model_sub_model')
        expect(@relation.definitions).to have_key('model_sub_sub_model')
      end
    end

    describe 'for has_many' do
      before(:each) do
        @relation = NotificationObservable::Filter::Schema::Relation.new(SubModel._reflections['sub_sub_models'])
        @schema = @relation.schema
      end

      it 'returns schema for relation' do
        expect(@schema).to include(
                             title: 'Related SubSubModel',
                             type: 'object',
                             required: ['sub_sub_models'],
                             properties: {
                               'sub_sub_models' => {
                                 '$ref' => '#/definitions/model_sub_sub_model'
                               }
                             }
                           )
      end

      it 'keeps definitions' do
        expect(@relation.definitions).to have_key('model_sub_sub_model')
      end
    end
  end
end
