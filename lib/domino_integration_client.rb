require 'uri'

class DominoIntegrationClient
  class CommandError < StandardError; end

  attr_reader :db_url, :db_base_url, :db_name

  def initialize(db_url, username, password)
    @db_url = db_url

    db_uri = URI(@db_url)
    @db_base_url = "#{db_uri.scheme}://#{db_uri.host}:#{db_uri.port}"
    @db_name = db_uri.path[1..-1]

    @username = username
    @password = password
  end

  def ensure_document_exists(query, form, create_properties, update_properties)
    documents = find_document(query)
    if documents.first
      unid = documents.first['@unid']
      update_document(unid, form, update_properties)
      unid
    else
      create_document(form, create_properties)
    end
  end

  def update_document(unid, form, properties)
    if Rails.application.config.domino_integration_readonly == :erica_id_only
      if properties['ericaID'].nil?
        return false
      else
        properties = { 'ericaID' => properties['ericaID'] }
      end
    elsif readonly?
      return false
    end

    documents_resource["unid/#{unid}"].patch(properties.to_json, form_params(form)) do |response|
      pp response if response.code == 400
      if response.code == 404
        :'404'
      else
        response.code == 200
      end
    end
  end

  def replica_id
    databases = list_databases
    return nil if databases.nil?

    our_database = databases.find { |database| database['@filepath'] == @db_name }
    return nil if our_database.nil?

    our_database['@replicaid']
  end

  def collection_unid(collection_name)
    collections = list_collections
    return nil if collections.nil?

    target_collection = collections.find { |collection| collection['@title'] == collection_name }
    return nil if target_collection.nil?

    target_collection['@unid']
  end

  def trash_document(unid, form)
    update_document(unid, form, 'Trash' => 1)
  end

  def untrash_document(unid, form)
    update_document(unid, form, 'Trash' => 0)
  end

  def get_document_by_unid(unid)
    perform_command do
      response = documents_resource["unid/#{unid}"].get
      JSON.parse(response.body)
    end
  end

  # query is a hash, specifying field name / value pairs
  def find_document(query)
    perform_command do
      response = documents_resource.get(search_params(query))
      JSON.parse(response.body)
    end
  end

  def create_document(form, properties)
    return nil if readonly?

    perform_command do
      response = documents_resource.post(properties.to_json, form_params(form))
      return unless response.code == 201
      response.headers[:location].split('/').last
    end
  end

  def readonly?
    Rails.application.config.domino_integration_readonly == true
  end

  protected

  attr_reader :username, :password

  def list_databases
    perform_command do
      response = databases_resource.get
      JSON.parse(response.body)
    end
  end

  def list_collections
    perform_command do
      response = collections_resource.get
      JSON.parse(response.body)
    end
  end

  def perform_command
    yield
  rescue JSON::JSONError => e
    raise CommandError, "Could not parse JSON response from Domino server: #{e}"
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    raise CommandError, "Could not authenticate with Domino Server as user #{username}"
  rescue RestClient::NotFound => e
    raise CommandError, "Domino Server reported `File or URL not found`: #{e}"
  end

  def rest_client_options
    @rest_client_options ||= {
      user: username,
      password: password,
      headers: {
        accept: 'application/json',
        content_type: 'application/json'
      }
    }
  end

  def databases_resource
    @databases_resource ||= RestClient::Resource.new(
      "#{db_base_url}/api/data",
      rest_client_options
    )
  end

  def documents_resource
    @documents_resource ||= RestClient::Resource.new(
      "#{db_url}/api/data/documents",
      rest_client_options
    )
  end

  def collections_resource
    @collections_resource ||= RestClient::Resource.new(
      "#{db_url}/api/data/collections",
      rest_client_options
    )
  end

  def form_params(form)
    {
      params: {
        form: form,
        computewithform: true
      }
    }
  end

  def query_string(query)
    case query
    when Hash then
      query
        .map { |field, value| "field #{field} = #{value}" }
        .join(' and ')
    when String then query
    else raise "Unable to create query string: #{query.inspect}"
    end
  end

  def search_params(query)
    {
      params: {
        search: query_string(query)
      }
    }
  end
end
