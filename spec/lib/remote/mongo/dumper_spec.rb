require 'remote/mongo/dumper'

RSpec.describe Mongo::Dumper do
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
      expect(Mongo::Dumper.mongo_options)
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
          'hosts'    => [
            'localhost:27017',
            'localhost:27018'
          ],
          'username' => 'testuser',
          'password' => 'testpass'
        )
      expect { Mongo::Dumper.mongo_options }
        .to raise_error('Cannot handle multiple hosts.')
    end
  end

  describe '#arguments' do
    it 'picks only allowed options' do
      allow(Rails.configuration.mongoid.clients)
        .to receive(:[]).with('default').and_return({})
      expect(Rails.configuration.mongoid.clients['default'])
        .to receive(:clone).and_return(
          'database' => 'erica_store_test',
          'hosts'    => ['localhost:27017'],
          'username' => 'testuser',
          'password' => 'testpass',
          'some'     => 'other_option'
        )
      args = Mongo::Dumper.arguments(out: 'test')
      expect(args).to include '--db=erica_store_test'
      expect(args).to include '--host=localhost'
      expect(args).to include '--port=27017'
      expect(args).to include '--username=testuser'
      expect(args).to include '--password=testpass'
      expect(args).to include '--out=test'
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
      expect(Mongo::Dumper)
        .to receive(:system_or_die)
        .with satisfy { |v|
          expect(v).to match /^mongodump/
          expect(v).to include '--db=erica_store_test'
          expect(v).to include '--host=localhost'
          expect(v).to include '--port=27017'
          expect(v).to include '--username=testuser'
          expect(v).to include '--password=testpass'
          expect(v).to include '--collection=patient_data'
        }
      Mongo::Dumper.dump(collection: 'patient_data')
    end
  end
end
