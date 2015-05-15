require 'remote/sql/column'

RSpec.describe Sql::Column do
  describe 'which is nullable' do
    before :each do
      @column = Sql::Column.new('table', OpenStruct.new(name: :nullable_column, type: :string, null: true, limit: nil))
    end

    describe '#catch_null' do
      it 'returns the given identifier wrapped in a NULL check' do
        expect(@column.catch_null { '"table"."nullable_column"' })
          .to eq %(CASE WHEN "table"."nullable_column" IS NULL THEN 'NULL' ELSE "table"."nullable_column" END)
      end
    end
  end

  describe 'which is not nullable' do
    before :each do
      @column = Sql::Column.new('table', OpenStruct.new(name: :integer_column, type: :integer, null: false, limit: nil))
    end

    describe '#catch_null' do
      it 'returns the given identifier without a NULL check' do
        expect(@column.catch_null { '"table"."column"' }).to eq '"table"."column"'
      end
    end
  end

  describe 'of type :integer' do
    before :each do
      @column = Sql::Column.new('table', OpenStruct.new(name: :integer_column, type: :integer, null: false, limit: nil))
    end

    describe '#to_s' do
      it 'returns the quoted name' do
        expect(@column.to_s).to eq '"integer_column"'
      end
    end

    describe 'with_type' do
      it 'returns the quoted column name with type cast' do
        expect(@column.with_type).to eq '"integer_column"::integer'
      end
    end

    describe 'with_ref' do
      it 'returns the quoted column identifier with table reference' do
        expect(@column.with_ref).to eq '"table"."integer_column"'
      end

      it 'returns the quoted column identifier with overridden reference' do
        expect(@column.with_ref(ref: 'ref')).to eq '"ref"."integer_column"'
      end
    end

    describe 'with_reftype' do
      it 'returns the quoted column identifier with table reference and type cast' do
        expect(@column.with_reftype).to eq '"table"."integer_column"::integer'
      end

      it 'returns the quoted column identifier with overridden reference and type cast' do
        expect(@column.with_reftype(ref: 'ref')).to eq '"ref"."integer_column"::integer'
      end
    end
  end
end
