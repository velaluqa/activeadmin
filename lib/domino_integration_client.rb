require 'uri'

class DominoIntegrationClient
  attr_reader :db_url, :db_base_url, :db_name

  def initialize(db_url, username, password)
    @db_url = db_url

    db_uri = URI(@db_url)
    @db_base_url = "#{db_uri.scheme}://#{db_uri.host}:#{db_uri.port}"
    @db_name = db_uri.path[1..-1]

    @databases_resource = RestClient::Resource.new(@db_base_url + '/api/data', user: username, password: password, headers: { accept: 'application/json', content_type: 'application/json' })

    @documents_resource = RestClient::Resource.new(@db_url + '/api/data/documents', user: username, password: password, headers: { accept: 'application/json', content_type: 'application/json' })
    @collections_resource = RestClient::Resource.new(@db_url + '/api/data/collections', user: username, password: password, headers: { accept: 'application/json', content_type: 'application/json' })
  end

  def ensure_document_exists(query, form, create_properties, update_properties)
    existing_documents = find_document(query)

    if existing_documents && existing_documents.respond_to?(:length) && !existing_documents.empty?
      unid = existing_documents[0]['@unid']
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
    elsif Rails.application.config.domino_integration_readonly == true
      return false
    end

    @documents_resource['unid/' + unid].patch(properties.to_json, params: { form: form, computewithform: true }) do |response|
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
    @documents_resource['unid/' + unid].get do |response|
      if response.code == 200
        begin
          JSON.parse(response.body)
        rescue JSON::JSONError => e
          raise 'Failed to parse JSON response from Domino server: ' + e.message
        end
      end
    end
  end

  # query is a hash, specifying field name / value pairs
  def find_document(query)
    if query.is_a?(Hash)
      query_string = query.map do |field, value|
        "field #{field} = #{value}"
      end.join(' and ')
    elsif query.is_a?(String)
      query_string = query
    else
      return nil
    end

    @documents_resource.get(params: { search: query_string }) do |response|
      if response.code == 200
        begin
          JSON.parse(response.body)
        rescue JSON::JSONError => e
          raise 'Failed to parse JSON response from Domino server: ' + e.message
        end
      end
    end
  end

  def create_document(form, properties)
    return nil unless Rails.application.config.domino_integration_readonly == false
    @documents_resource.post(properties.to_json, params: { form: form, computewithform: true }) do |response|
      response.headers[:location].split('/').last if response.code == 201
    end
  end

  protected

  def list_databases
    @databases_resource.get do |response|
      if response.code == 200
        begin
          JSON.parse(response.body)
        rescue JSON::JSONError => e
          raise 'Failed to parse JSON response from Domino server: ' + e.message
        end
      end
    end
  end

  def list_collections
    @collections_resource.get do |response|
      if response.code == 200
        begin
          JSON.parse(response.body)
        rescue JSON::JSONError => e
          raise 'Failed to parse JSON response from Domino server: ' + e.message
        end
      end
    end
  end
end
