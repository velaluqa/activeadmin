class DominoIntegrationClient
  attr_reader :db_url

  def initialize(db_url, username, password)
    @db_url = db_url

    @documents_resource = RestClient::Resource.new(@db_url + '/api/data/documents', :user => username, :password => password, :headers => {:accept => 'application/json', :content_type => 'application/json'})
  end

  def ensure_document_exists(query, form, properties)
    existing_documents = find_document(query)

    if(existing_documents and existing_documents.respond_to?(:length) and existing_documents.length > 0)
      unid = existing_documents[0]['@unid']
      update_document(unid, form, properties)

      unid
    else
      create_document(form, properties)
    end
  end

  def update_document(unid, form, properties)
    return @documents_resource['unid/'+unid].patch(properties.to_json, {:params => {:form => form, :computewithform => true}}) do |response|
      response.code == 200
    end
  end

  protected
    
  def create_document(form, properties)
    return @documents_resource.post(properties.to_json, {:params => {:form => form, :computewithform => true}}) do |response|
      if(response.code == 201)
        pp response.headers
        response.headers[:location].split('/').last
      else
        nil
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

    return @documents_resource.get({:params => {:search => query_string}}) do |response|
      if(response.code == 200)
        JSON::parse(response.body)
      else
        nil
      end
    end
  end
end
