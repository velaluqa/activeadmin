require 'remote/mongo/restore'

RSpec.describe Mongo::Restore do
  describe '#mongodump_options' do
    it 'splits the host string into host and port' do
      allow(Rails.configuration.mongoid.clients)
        .to receive(:[]).with('default').and_return({})
      expect(Rails.configuration.mongoid.clients['default'])
        .to receive(:clone).and_return(
          'database' => 'erica_store_test',
          'hosts'    => ['localhost:27017'],
          'username' => 'testuser',
          'password' => 'testpass'
        )
      expect(Mongo::Restore.mongo_options)
        .to eq(
          'db'       => 'erica_store_test',
          'host'     => 'localhost',
          'port'     => '27017',
          'username' => 'testuser',
          'password' => 'testpass'
        )
    end

    it 'fails for more than one host' do
      allow(Rails.configuration.mongoid.clients)
        .to receive(:[]).with('default').and_return({})
      expect(Rails.configuration.mongoid.clients['default'])
        .to receive(:clone).and_return(
          'database' => 'erica_store_test',
          'hosts'    => ['localhost:27017', 'localhost:27018'],
          'username' => 'testuser',
          'password' => 'testpass'
        )
      expect { Mongo::Restore.mongo_options }
        .to raise_error('Cannot handle multiple hosts.')
    end
  end

  describe '#format_argument' do
    it 'takes key and value as an array' do
      expect(Mongo::Restore.format_argument([:key, 'value'])).to eq '--key=value'
    end

    it 'takes key and value as two arguments' do
      expect(Mongo::Restore.format_argument(:key, 'value')).to eq '--key=value'
    end

    it 'returns an escaped option if given value is a defined string-like object' do
      expect(Mongo::Restore.format_argument(:key, "ma' value"))
        .to eq "--key=ma\\'\\ value"
    end

    it 'returns a flag if given value is true' do
      expect(Mongo::Restore.format_argument(:key, true)).to eq '--key'
    end

    it 'returns nil if given value is false' do
      expect(Mongo::Restore.format_argument(:key, false)).to be_nil
    end

    it 'returns nil if given value is nil' do
      expect(Mongo::Restore.format_argument(:key, nil)).to be_nil
    end
  end

  describe '#arguments' do
    it 'picks only allowed option keys' do
      allow(Rails.configuration.mongoid.clients)
        .to receive(:[]).with('default').and_return({})
      expect(Rails.configuration.mongoid.clients['default'])
        .to receive(:clone).and_return(
          'database' => 'erica_store_test',
          'hosts'    => ['localhost:27017'],
          'username' => 'testuser',
          'password' => 'testpass',
          'some'     => 'other_option',
          'drop'     => true
        )
      args = Mongo::Restore.arguments
      expect(args).to include '--db=erica_store_test'
      expect(args).to include '--host=localhost'
      expect(args).to include '--port=27017'
      expect(args).to include '--username=testuser'
      expect(args).to include '--password=testpass'
      expect(args).to include '--drop'
    end
  end

  describe 'dump' do
    before :each do
      allow(Rails.configuration.mongoid.clients)
        .to receive(:[]).with('default').and_return({})
      expect(Rails.configuration.mongoid.clients['default'])
        .to receive(:clone).and_return(
          'database' => 'erica_store_test',
          'hosts'    => ['localhost:27017'],
          'username' => 'testuser',
          'password' => 'testpass'
        )
    end

    it 'runs the correct command' do
      expect(Mongo::Restore)
        .to receive(:system_or_die)
        .with satisfy { |v|
          expect(v).to match(/^mongorestore/)
          expect(v).to include '--db=erica_store_test'
          expect(v).to include '--host=localhost'
          expect(v).to include '--port=27017'
          expect(v).to include '--username=testuser'
          expect(v).to include '--password=testpass'
          expect(v).to include '--drop'
          expect(v).to include '/some/directory'
        }
      Mongo::Restore.from_dir('/some/directory')
    end
  end
end
