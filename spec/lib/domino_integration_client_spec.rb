require 'domino_integration_client'

RSpec.describe DominoIntegrationClient do
  let(:client) do
    DominoIntegrationClient.new(
      'https://domino-server.local/Pharmtrace/340060.nsf',
      'username',
      'password'
    )
  end

  describe '::replica_id' do
    it 'raises authentication error' do
      stub_request(:get, 'https://username:password@domino-server.local:443/api/data')
        .to_return(status: 403)
      expect { client.replica_id }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not authenticate/
        )
    end

    it 'raises database not found error' do
      stub_request(:get, 'https://username:password@domino-server.local:443/api/data')
        .to_return(status: 404)
      expect { client.replica_id }.to raise_error(
        DominoIntegrationClient::CommandError,
        /File or URL not found/
      )
    end

    it 'raises JSON parsing error' do
      stub_request(:get, 'https://username:password@domino-server.local:443/api/data')
        .to_return(status: 200, body: '{')
      expect { client.replica_id }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not parse JSON response/
        )
    end
  end

  describe '::collection_unid' do
    it 'raises authentication error' do
      stub_request(:get, 'https://username:password@domino-server.local/Pharmtrace/340060.nsf/api/data/collections')
        .to_return(status: 403)
      expect { client.collection_unid('All') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not authenticate/
        )
    end

    it 'raises database not found error' do
      stub_request(:get, 'https://username:password@domino-server.local/Pharmtrace/340060.nsf/api/data/collections')
        .to_return(status: 404)
      expect { client.collection_unid('All') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /File or URL not found/
        )
    end

    it 'raises JSON parsing error' do
      stub_request(:get, 'https://username:password@domino-server.local/Pharmtrace/340060.nsf/api/data/collections')
        .to_return(status: 200, body: '{')
      expect { client.collection_unid('All') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not parse JSON response/
        )
    end
  end

  describe '#find_document' do
    it 'raises authentication error' do
      stub_request(:get, 'https://username:password@domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20abc%20=%201')
        .to_return(status: 403)
      expect { client.find_document('field abc = 1') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not authenticate/
        )
    end

    it 'raises database not found error' do
      stub_request(:get, 'https://username:password@domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20abc%20=%201')
        .to_return(status: 404)
      expect { client.find_document('field abc = 1') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /File or URL not found/
        )
    end

    it 'raises JSON parsing error' do
      stub_request(:get, 'https://username:password@domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20abc%20=%201')
        .to_return(status: 200, body: '{')
      expect { client.find_document('field abc = 1') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not parse JSON response/
        )
    end

    it 'creates query string for search params from hash' do
      stub = stub_request(:get, 'https://username:password@domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20foo%20=%201%20and%20field%20bar%20=%20haha')
               .to_return(status: 200, body: '{}')
      expect(client.find_document(foo: 1, bar: 'haha')).to eq({})
      expect(stub).to have_been_requested
    end
  end
end
