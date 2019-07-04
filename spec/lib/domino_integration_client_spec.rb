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
      stub_request(:get, 'https://domino-server.local:443/api/data')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 403)
      expect { client.replica_id }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not authenticate/
        )
    end

    it 'raises database not found error' do
      stub_request(:get, 'https://domino-server.local:443/api/data')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 404)
      expect { client.replica_id }.to raise_error(
        DominoIntegrationClient::CommandError,
        /File or URL not found/
      )
    end

    it 'raises RestClient::RequestFailed error' do
      stub_request(:get, 'https://domino-server.local:443/api/data')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 400, body: <<~JSON)
{
  "code": 400,
  "text": "Bad Request",
  "message": "This is a domino specific message",
  "data": "domino stack trace"
}
JSON
      expect { client.replica_id }
        .to raise_error(
              DominoIntegrationClient::CommandError,
              /Domino Request Error: 400 Bad Request: This is a domino specific message/
            )
    end

    it 'raises JSON parsing error' do
      stub_request(:get, 'https://domino-server.local:443/api/data')
        .with(basic_auth: ['username', 'password'])
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
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/collections')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 403)
      expect { client.collection_unid('All') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not authenticate/
        )
    end

    it 'raises database not found error' do
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/collections')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 404)
      expect { client.collection_unid('All') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /File or URL not found/
        )
    end

    it 'raises RestClient::RequestFailed error' do
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/collections')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 400, body: <<~JSON)
{
  "code": 400,
  "text": "Bad Request",
  "message": "This is a domino specific message",
  "data": "domino stack trace"
}
JSON
      expect { client.collection_unid('All') }
        .to raise_error(
              DominoIntegrationClient::CommandError,
              /Domino Request Error: 400 Bad Request: This is a domino specific message/
            )
    end

    it 'raises JSON parsing error' do
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/collections')
        .with(basic_auth: ['username', 'password'])
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
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20abc%20=%201')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 403)
      expect { client.find_document('field abc = 1') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not authenticate/
        )
    end

    it 'raises database not found error' do
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20abc%20=%201')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 404)
      expect { client.find_document('field abc = 1') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /File or URL not found/
        )
    end

    it 'raises JSON parsing error' do
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20abc%20=%201')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 200, body: '{')
      expect { client.find_document('field abc = 1') }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not parse JSON response/
        )
    end

    it 'raises RestClient::RequestFailed error' do
      stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20abc%20=%201')
        .with(basic_auth: ['username', 'password'])
        .to_return(status: 400, body: <<~JSON)
{
  "code": 400,
  "text": "Bad Request",
  "message": "This is a domino specific message",
  "data": "domino stack trace"
}
JSON
      expect { client.find_document('field abc = 1') }
        .to raise_error(
              DominoIntegrationClient::CommandError,
              /Domino Request Error: 400 Bad Request: This is a domino specific message/
            )
    end

    it 'creates query string for search params from hash' do
      stub = stub_request(:get, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents?search=field%20foo%20=%201%20and%20field%20bar%20=%20haha')
               .with(basic_auth: ['username', 'password'])
               .to_return(status: 200, body: '{}')
      expect(client.find_document(foo: 1, bar: 'haha')).to eq({})
      expect(stub).to have_been_requested
    end
  end

  describe '#update_document' do
    it 'raises authentication error' do
      stub_request(:patch, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents/unid/123?computewithform=true&form=TrialSubject')
        .with(basic_auth: ['username', 'password'])
        .with(body: { name: 'New Name' }.to_json)
        .to_return(status: 403)
      expect { client.update_document('123', 'TrialSubject', { name: 'New Name' }) }
        .to raise_error(
          DominoIntegrationClient::CommandError,
          /Could not authenticate/
        )
    end

    it 'return :404 if not found error' do
      stub_request(:patch, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents/unid/123?computewithform=true&form=TrialSubject')
        .with(basic_auth: ['username', 'password'])
        .with(body: { name: 'New Name' }.to_json)
        .to_return(status: 404)
      result = client.update_document('123', 'TrialSubject', { name: 'New Name' })
      expect(result).to eq(:'404')
    end

    it 'returns false upon RestClient::BadRequest' do
      stub_request(:patch, 'https://domino-server.local/Pharmtrace/340060.nsf/api/data/documents/unid/123?computewithform=true&form=TrialSubject')
        .with(basic_auth: ['username', 'password'])
        .with(body: { name: 'New Name' }.to_json)
        .to_return(status: 400, body: <<~JSON)
{
  "code": 400,
  "text": "Bad Request",
  "message": "This is a domino specific message",
  "data": "domino stack trace"
}
JSON
      result = client.update_document('123', 'TrialSubject', { name: 'New Name' })
      expect(result).to eq(false)
    end
  end
end
