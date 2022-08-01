# This is an extraction of the naive "full-text search" implemented by
# Max Wolter earlier. It unions all accessible MODELS  for given user
# with concatenated interesting fields to perform a match search.
#
# The searchable MODELS must all implement a `granted_by` and a
# `searchable` scope.
#
# TODO: Use a more performant, sophisticated full-text search (maybe
# something like Apache SOLR or similar...)
class RecordSearch
  MODELS =
    %w[BackgroundJob Study Center Patient Visit ImageSeries Image User Role RequiredSeries ActiveAdmin::Comment FormAnswer].freeze

  attr_accessor :user, :query, :study_id, :models

  def initialize(options = {})
    (@user = options[:user]) || raise('missing :user options')
    (@query = options[:query]) || raise('missing :query options')
    @models = (options[:models].blank? ? MODELS : options[:models] & MODELS)
    @study_id = options[:study_id]
  end

  def results
    return [] if record_queries.empty?
    ActiveRecord::Base.connection.execute(merged_query).to_a
  end

  private

  def merged_query
    q = "SELECT * FROM (#{unioned_queries}) q WHERE q.text LIKE '%#{query}%'"
    q << " AND (q.study_id = '#{study_id}' OR q.study_id IS NULL)" if study_id
    q
  end

  def unioned_queries
    record_queries.reject(&:blank?).join(' UNION ')
  end

  def record_queries
    models.map do |model|
      model
        .constantize
        .granted_for(activity: :read, user: user)
        .try(:searchable)
        .try(:to_sql)
    end
  end

  def self.find_record(record_search_id)
    type, id = record_search_id.split("_")
    case type
    when "BackgroundJob" then BackgroundJob.find(id)
    when "Study" then Study.find(id)
    when "Center" then Center.find(id)
    when "Patient" then Patient.find(id)
    when "Visit" then Visit.find(id)
    when "ImageSeries" then ImageSeries.find(id)
    when "Image" then Image.find(id)
    when "User" then User.find(id)
    when "Role" then Role.find(id)
    when "RequiredSeries" then RequiredSeries.find(id)
    when "Comment" then ActiveAdmin::Comments.find(id)
    when "FormAnswer" then FormAnswer.find(id)
    else fail "Unknown record search type #{type.inspect}"
    end
  end
end
