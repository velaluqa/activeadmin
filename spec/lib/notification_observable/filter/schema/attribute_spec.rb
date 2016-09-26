RSpec.describe NotificationObservable::Filter::Schema::Attribute do
  with_model :TestModel do
    table do |t|
      t.integer :integer_field, null: true
      t.bigint :bigint_field
      t.float :float_field
      t.decimal :decimal_field
      t.string :string1_field
      t.string :string2_field
      t.string :string3_field
      t.string :string4_field
      t.datetime :datetime_field
      t.date :date_field
      t.time :time_field
      t.binary :binary_field
      t.boolean :boolean_field
      t.string :enum_field
      t.string :notnull_field, null: false
    end
    model do
      validates :integer_field, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 10 }
      validates :bigint_field, numericality: { greater_than: 5, less_than: 10 }
      validates :float_field, numericality: { greater_than_or_equal_to: 1.1, less_than_or_equal_to: 1.8 }
      validates :decimal_field, numericality: { greater_than: 1.1, less_than: 1.8 }
      validates :string1_field, length: { minimum: 2, maximum: 10 }
      validates :string2_field, length: { in: 2..10 }
      validates :string3_field, length: { is: 6 }
      validates :string4_field, format: { with: /\A[a-zA-Z]+\z/ }
      validates :enum_field, inclusion: { in: %i(yes no maybe) }
    end
  end

  describe '#schema' do
    before(:each) do
      @column = TestModel.columns.first
      @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
      @schema = @attr.schema(filters: %i(matches changes))
    end

    it 'is of type `object`' do
      expect(@schema).to include(type: 'object')
    end
    it 'requires column name' do
      expect(@schema).to include(required: %w(id))
    end
    it 'defines property schema for column name' do
      expect(@schema.dig2(:properties)).to have_key('id')
      expect(@schema.dig2(:properties, 'id')).to have_key(:oneOf)
    end
  end

  describe '#filters' do
    before(:each) do
      @column = TestModel.columns.first
      @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
    end

    it 'returns only schemas from options[:filters]' do
      matches_filter = @attr.matches_filter
      changes_filter = @attr.changes_filter
      expect(@attr.filters(filters: %i(matches changes))).to include(matches_filter)
      expect(@attr.filters(filters: %i(matches changes))).to include(changes_filter)
      expect(@attr.filters(filters: %i(changes))).to include(changes_filter)
      expect(@attr.filters(filters: %i(changes))).not_to include(matches_filter)
      expect(@attr.filters(filters: %i(matches))).not_to include(changes_filter)
      expect(@attr.filters(filters: %i(matches))).to include(matches_filter)
    end
  end

  describe '#matches_filter' do
    before(:each) do
      @column = TestModel.columns.first
      @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
      @filter = @attr.matches_filter
    end

    it 'requires `matches` property' do
      expect(@filter).to include(required: %w(matches))
    end

    it 'validates the value' do
      expect(@filter.dig2(:properties, :matches)).to eq @attr.validation
    end
  end

  describe '#changes_filter' do
    before(:each) do
      @column = TestModel.columns.first
      @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
      @filter = @attr.changes_filter
    end

    it 'requires `changes` property' do
      expect(@filter).to include(required: %w(changes))
    end

    it 'validates the from value' do
      expect(@filter.dig2(:properties, :changes, :properties, :from)).to eq @attr.validation
    end

    it 'validates the to value' do
      expect(@filter.dig2(:properties, :changes, :properties, :to)).to eq @attr.validation
    end
  end

  describe '#validation' do
    describe 'for nullable column' do
      before(:each) do
        @column = TestModel.columns_hash['integer_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.validation
        expect(@validation).to be_a(Hash)
      end

      it 'allows null' do
        expect(@validation[:oneOf]).to include(title: 'null', type: 'null')
      end

      it 'allows value for column' do
        expect(@validation[:oneOf]).to include(@attr.value_validation)
      end
    end

    describe 'for not-null column' do
      before(:each) do
        @column = TestModel.columns_hash['notnull_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.validation
      end

      it 'denies null' do
        expect(@validation[:oneOf]).not_to include(include(type: 'null'))
      end
      it 'allows values for column' do
        expect(@validation[:oneOf]).to include(@attr.value_validation)
      end
    end
  end

  describe '#value_validation' do
    describe 'for integer column' do
      before(:each) do
        @column = TestModel.columns_hash['integer_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'integer')
        expect(@validation).to include(minimum: 5)
        expect(@validation).to include(maximum: 10)
        expect(@validation).not_to include(exclusiveMinimum: true)
        expect(@validation).not_to include(exclusiveMaximum: true)
      end
    end
    describe 'for bigint column' do
      before(:each) do
        @column = TestModel.columns_hash['bigint_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'integer')
        expect(@validation).to include(minimum: 5, exclusiveMinimum: true)
        expect(@validation).to include(maximum: 10, exclusiveMaximum: true)
      end
    end
    describe 'for float column' do
      before(:each) do
        @column = TestModel.columns_hash['float_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'number')
        expect(@validation).to include(minimum: 1.1)
        expect(@validation).to include(maximum: 1.8)
        expect(@validation).not_to include(exclusiveMinimum: true)
        expect(@validation).not_to include(exclusiveMaximum: true)
      end
    end
    describe 'for decimal column' do
      before(:each) do
        @column = TestModel.columns_hash['decimal_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'number')
        expect(@validation).to include(minimum: 1.1)
        expect(@validation).to include(maximum: 1.8)
        expect(@validation).to include(exclusiveMinimum: true)
        expect(@validation).to include(exclusiveMaximum: true)
      end
    end
    describe 'for string column' do
      describe 'with min/max length validation' do
        before(:each) do
          @column = TestModel.columns_hash['string1_field']
          @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
          @validation = @attr.value_validation
        end

        it 'returns the correct schema' do
          expect(@validation).to include(type: 'string')
          expect(@validation).to include(minLength: 2)
          expect(@validation).to include(maxLength: 10)
        end
      end
      describe 'with range length validation' do
        before(:each) do
          @column = TestModel.columns_hash['string2_field']
          @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
          @validation = @attr.value_validation
        end

        it 'returns the correct schema' do
          expect(@validation).to include(type: 'string')
          expect(@validation).to include(minLength: 2)
          expect(@validation).to include(maxLength: 10)
        end
      end
      describe 'with exact length validation' do
        before(:each) do
          @column = TestModel.columns_hash['string3_field']
          @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
          @validation = @attr.value_validation
        end

        it 'returns the correct schema' do
          expect(@validation).to include(type: 'string')
          expect(@validation).to include(minLength: 6)
          expect(@validation).to include(maxLength: 6)
        end
      end
      describe 'with pattern validation' do
        before(:each) do
          @column = TestModel.columns_hash['string4_field']
          @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
          @validation = @attr.value_validation
        end

        it 'returns the correct schema' do
          expect(@validation).to include(type: 'string')
          expect(@validation).to include(pattern: /\A[a-zA-Z]+\z/)
        end
      end
    end
    describe 'for datetime column' do
      before(:each) do
        @column = TestModel.columns_hash['datetime_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'string')
        expect(@validation).to include(format: 'datetime')
      end
    end
    describe 'for date column' do
      before(:each) do
        @column = TestModel.columns_hash['date_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'string')
        expect(@validation).to include(format: 'date')
      end
    end
    describe 'for time column' do
      before(:each) do
        @column = TestModel.columns_hash['time_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'string')
        expect(@validation).to include(format: 'time')
      end
    end
    describe 'for binary column' do
      before(:each) do
        @column = TestModel.columns_hash['binary_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'boolean')
        expect(@validation).to include(format: 'checkbox')
      end
    end
    describe 'for boolean column' do
      before(:each) do
        @column = TestModel.columns_hash['boolean_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'boolean')
        expect(@validation).to include(format: 'checkbox')
      end
    end
    describe 'for enum column' do
      before(:each) do
        @column = TestModel.columns_hash['enum_field']
        @attr = NotificationObservable::Filter::Schema::Attribute.new(TestModel, @column)
        @validation = @attr.value_validation
      end

      it 'returns the correct schema' do
        expect(@validation).to include(type: 'string')
        expect(@validation).to include(enum: %w(yes no maybe))
      end
    end
  end
end
