require 'remote/sql/restore'

RSpec.describe Sql::Restore do
  before(:each) do
    expect(Rails.configuration)
      .to receive(:database_configuration).at_least(:once).and_return(
        Rails.env => {
          'adapter'  => 'postgresql',
          'encoding' => 'unicode',
          'pool'     => 30,
          'timeout'  => 5000,
          'database' => 'erica_remote_test',
          'host'     => 'localhost',
          'port'     => 5432,
          'username' => 'testuser',
          'password' => 'testpassword%&$'
        }
      )
  end

  describe '#psql_options' do
    it 'removes unnecessary options' do
      expect(Sql::Restore.psql_options.keys)
        .to match_array %w(dbname host port username)
    end
  end

  describe 'psql' do
    it 'runs the correct command' do
      expect(Sql::Restore)
        .to receive(:system)
        .with satisfy { |v|
          expect(v).to start_with('PGPASSWORD=testpassword\%\&\$ psql')
          expect(v).to include('--dbname=erica_remote_test')
          expect(v).to include('--host=localhost')
          expect(v).to include('--port=5432')
          expect(v).to include('--username=testuser')
        }
      Sql::Restore.psql
    end

    it 'takes additional options' do
      expect(Sql::Restore)
        .to receive(:system)
        .with satisfy { |v|
          expect(v).to include('--file=abc')
        }
      Sql::Restore.psql(file: 'abc')
    end
  end
end
