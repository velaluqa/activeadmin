# note: this is not a proper activerecord model
# it is a simple container class implementing the bare bones needed by the view components of activeadmin

# TODO: Use a (materialized?) view via postgres to allow readonly
# access to required series via ActiveRecord:
#     tqc_state int,
# SELECT
#  json_build_array(visits.id, visits_required_series_hash.key) AS id,
#  visits.id AS visit_id,
#  visits_required_series_hash.key AS name,
#  image_series_id,
#  tqc_state,
#  tqc_user_id,
#  tqc_date,
#  tqc_version,
#  tqc_results,
#  tqc_comment
# FROM visits
# JOIN json_each(visits.required_series::json) visits_required_series_hash ON true
# JOIN json_to_record(visits_required_series_hash.value)
#   AS visits_required_series(
#     image_series_id int,
#     tqc_state int,
#     tqc_user_id int,
#     tqc_date timestamp,
#     tqc_version text,
#     tqc_results json,
#     tqc_comment text
# ) ON true
# INNER JOIN patients p ON p.id = visits.patient_id
# INNER JOIN centers c ON c.id = p.center_id
# WHERE
#   image_series_id IS NOT NULL
class RequiredSeries
  extend ActiveModel::Naming
  include DominoDocument

  attr_reader(
    :visit,
    :name,
    :image_series_id,
    :assigned_image_series,
    :tqc_results,
    :tqc_date,
    :tqc_version,
    :tqc_user_id,
    :tqc_state,
    :tqc_comment,
    :tqc_user,
    :domino_unid
  )

  def self.find(id)
    visit = Visit.find(id[0])
    RequiredSeries.new(visit, id[1])
  end

  def self.count_for_study(_study_id)
    res = ActiveRecord::Base.connection.execute(<<QUERY)
SELECT
  COUNT(image_series_id) AS count
FROM visits
JOIN json_each(visits.required_series::json) visits_required_series_hash ON true
JOIN json_to_record(visits_required_series_hash.value)
  AS visits_required_series(
    image_series_id int,
    tqc_state int
) ON true
INNER JOIN patients p ON p.id = visits.patient_id
INNER JOIN centers c ON c.id = p.center_id
WHERE
  image_series_id IS NOT NULL AND tqc_state IS NOT NULL
QUERY
    res.first['count'].to_i
  end

  def self.grouped_count_for_study(_study_id, _group)
    res = ActiveRecord::Base.connection.execute(<<QUERY)
SELECT
  tqc_state AS group,
  COUNT(image_series_id) AS count
FROM visits
JOIN json_each(visits.required_series::json) visits_required_series_hash ON true
JOIN json_to_record(visits_required_series_hash.value)
  AS visits_required_series(
    image_series_id int,
    tqc_state int
) ON true
INNER JOIN patients p ON p.id = visits.patient_id
INNER JOIN centers c ON c.id = p.center_id
WHERE
  image_series_id IS NOT NULL
  AND tqc_state IS NOT NULL
GROUP BY
  tqc_state
QUERY
    res
      .map { |result| [result['group'], result['count'].to_i] }
      .to_h
  end

  def initialize(visit, name)
    @visit = visit
    @name = name

    data = visit.required_series[name]
    if data
      @image_series_id = data['image_series_id']
      @tqc_results = data['tqc_results']
      @tqc_comment = data['tqc_comment']
      @tqc_date =
        case data['tqc_date']
        when Time then data['tqc_date']
        when String then Time.parse(data['tqc_date'])
        end
      @tqc_version = data['tqc_version']
      @tqc_user_id = data['tqc_user_id']
      @tqc_state = data['tqc_state'] || RequiredSeries.tqc_state_sym_to_int(:pending)

      @domino_unid = data['domino_unid']
    end
  end

  def id
    [(@visit.nil? ? nil : @visit.id), @name]
  end

  def to_key
    nil
  end

  def study
    @visit.study
  end

  def assigned?
    !@image_series_id.blank?
  end

  def assigned_image_series
    @assigned_image_series ||= ImageSeries.where(id: @image_series_id, visit_id: @visit.id).first unless @image_series_id.nil?

    @assigned_image_series
  end

  def tqc_user
    @tqc_user ||= User.where(id: @tqc_user_id).first unless @tqc_user_id.nil?

    @tqc_user
  end

  TQC_STATE_SYMS = [:pending, :issues, :passed].freeze

  def self.tqc_state_sym_to_int(sym)
    RequiredSeries::TQC_STATE_SYMS.index(sym)
  end

  def tqc_state
    return -1 if @tqc_state.nil?
    RequiredSeries::TQC_STATE_SYMS[@tqc_state]
  end

  def locked_spec
    spec_at_version(study.locked_version)
  end

  def spec_at_version(version)
    required_series_specs = @visit.required_series_specs_at_version(version)
    return nil if required_series_specs.nil?

    required_series_specs[@name]
  end

  def locked_tqc_spec
    tqc_spec_at_version(study.locked_version)
  end

  def tqc_spec_at_version(version)
    spec = spec_at_version(version)
    return nil if spec.nil?

    spec['tqc']
  end

  def tqc_spec_with_results
    tqc_spec_with_results_at_version(tqc_version || study.locked_version)
  end

  def locked_tqc_spec_with_results
    tqc_spec_with_results_at_version(study.locked_version)
  end

  def tqc_spec_with_results_at_version(version)
    tqc_spec = tqc_spec_at_version(version)
    return nil if tqc_spec.nil? || @tqc_results.nil?

    tqc_spec.each do |question|
      question['answer'] = @tqc_results[question['id']]
    end

    tqc_spec
  end

  def wado_query
    return nil unless assigned?

    { id: (@visit.nil? ? '_' + name : @visit.id.to_s + '_' + name), name: name, images: assigned_image_series.images.order('id ASC') }
  end

  def domino_document_form
    'RequiredSeries'
  end

  def domino_document_query
    {
      'docCode' => 10_044,
      'ericaID' => @visit.id,
      'RequiredSeries' => name
    }
  end

  def domino_document_properties(_action = :update)
    properties = {
      'ericaID' => @visit.id,
      'CenterNo' => @visit.patient.center.code,
      'PatNo' => @visit.patient.domino_patient_no,
      'VisitNo' => @visit.visit_number,
      'RequiredSeries' => name
    }

    if assigned_image_series.nil?
      properties.merge!('trash' => 1,
                        'ericaASID' => nil,
                        'DateImaging' => '01-01-0001',
                        'SeriesDescription' => nil,
                        'DICOMTagNames' => nil,
                        'DICOMValues' => nil)
    else
      properties.merge!('trash' => 0,
                        'ericaASID' => assigned_image_series.id,
                        'DateImaging' => { 'data' => assigned_image_series.imaging_date.strftime('%d-%m-%Y'), 'type' => 'datetime' },
                        'SeriesDescription' => assigned_image_series.name)
      properties.merge!(assigned_image_series.dicom_metadata_to_domino)
    end
    properties.merge!(tqc_to_domino)

    properties
  end

  def domino_unid=(new_unid)
    if visit.required_series
      visit.required_series[name] ||= {}
      visit.required_series[name]['domino_unid'] = new_unid
      visit.save
    end
  end

  def domino_sync
    ensure_domino_document_exists
  end

  protected

  def tqc_to_domino
    result = {}

    result['QCdate'] = { 'data' => (tqc_date.nil? ? '01-01-0001' : tqc_date.strftime('%d-%m-%Y')), 'type' => 'datetime' }
    result['QCperson'] = (tqc_user.nil? ? nil : tqc_user.name)

    result['QCresult'] =
      case tqc_state
      when :pending then 'Pending'
      when :issues then 'Performed, issues present'
      when :passed then 'Performed, no issues present'
      end

    result['QCcomment'] = tqc_comment

    criteria_names = []
    criteria_values = []
    results = tqc_spec_with_results_at_version(tqc_version || study.locked_version)
    if results.nil?
      result['QCCriteriaNames'] = nil
      result['QCValues'] = nil
    else
      results.each do |criterion|
        criteria_names << criterion['label']
        criteria_values << (criterion['answer'] == true ? 'Pass' : 'Fail')
      end

      result['QCCriteriaNames'] = criteria_names.join("\n")
      result['QCValues'] = criteria_values.join("\n")
    end

    result
  end
end
