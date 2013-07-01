require 'domino_document_mixin'

# note: this is not a proper activerecord model
# it is a simple container class implementing the bare bones needed by the view components of activeadmin

class RequiredSeries
  extend ActiveModel::Naming
  include DominoDocument

  attr_reader :visit, :name
  attr_reader :image_series_id, :assigned_image_series
  attr_reader :tqc_results, :tqc_date, :tqc_version, :tqc_user_id, :tqc_state
  attr_reader :tqc_user
  attr_reader :domino_unid

  def initialize(visit, name)
    @visit = visit
    @name = name

    visit.ensure_visit_data_exists
    data = visit.visit_data['required_series'][name]
    unless(data.nil?)
      @image_series_id = data['image_series_id']
      @tqc_results = data['tqc_results']
      @tqc_date = data['tqc_date']
      @tqc_version = data['tqc_version']
      @tqc_user_id = data['tqc_user_id']
      @tqc_state = data['tqc_state'] || RequiredSeries.tqc_state_sym_to_int(:pending)

      @domino_unid = data['domino_unid']
    end
  end

  def to_key
    nil
  end
  
  def study
    @visit.study
  end

  def assigned?
    return (not @image_series_id.blank?)
  end
  def assigned_image_series
    @assigned_image_series ||= ImageSeries.where(:id => @image_series_id, :visit_id => @visit.id).first unless @image_series_id.nil?

    return @assigned_image_series
  end
  def tqc_user
    @tqc_user ||= User.where(:id => @tqc_user_id).first unless @tqc_user_id.nil?

    return @tqc_user
  end

  TQC_STATE_SYMS = [:pending, :issues, :passed]

  def self.tqc_state_sym_to_int(sym)
    return RequiredSeries::TQC_STATE_SYMS.index(sym)
  end
  def tqc_state
    return -1 if @tqc_state.nil?
    return RequiredSeries::TQC_STATE_SYMS[@tqc_state]
  end

  def spec
    required_series_specs = @visit.required_series_specs
    return nil if required_series_specs.nil?

    return required_series_specs[@name]
  end
  def tqc_spec
    spec = self.spec
    return nil if spec.nil?

    return spec['tqc']
  end

  def tqc_spec_with_results
    tqc_spec = self.tqc_spec
    return nil if tqc_spec.nil? or @tqc_results.nil?

    tqc_spec.each do |question|
      question['answer'] = @tqc_results[question['id']]
    end

    return tqc_spec
  end

  def domino_document_form
    'RequiredSeries'
  end
  def domino_document_query
    {
      'docCode' => 10044,
      'ericaID' => @visit.id,
      'RequiredSeries' => self.name
    }
  end
  def domino_document_properties(action = :update)
    properties = {
      'ericaID' => @visit.id,
      'CenterNo' => @visit.patient.center.code,
      'PatNo' => @visit.patient.domino_patient_no,
      'VisitNo' => @visit.visit_number,
      'RequiredSeries' => self.name,
    }

    unless(self.assigned_image_series.nil?)
      properties.merge!({
                          'ericaASID' => self.assigned_image_series.id,
                          'DateImaging' => {'data' => self.assigned_image_series.imaging_date.strftime('%d-%m-%Y'), 'type' => 'datetime'},
                          'SeriesDescription' => self.assigned_image_series.name,
                        })
      properties.merge!(self.assigned_image_series.dicom_metadata_to_domino)

      properties.merge!(tqc_to_domino)
    end

    return properties
  end

  def domino_unid=(new_unid)
    visit_data = visit.visit_data
    unless(visit_data.nil? or visit_data.required_series.nil?)
      visit_data.required_series[self.name] ||= {}
      visit_data.required_series[self.name]['domino_unid'] = new_unid

      visit_data.save
    end
  end
  def domino_sync
    if(self.assigned?)
      self.ensure_domino_document_exists
    elsif(not self.domino_unid.blank?)
      self.trash_document
      self.domino_unid = nil
    else
      return true
    end
  end

  protected

  def tqc_to_domino
    result = {}

    result['QCdate'] = {'data' => self.tqc_date.strftime('%d-%m-%Y'), 'type' => 'datetime'} unless self.tqc_date.nil?
    result['QCperson'] = self.tqc_user.name unless self.tqc_user.nil?

    result['QCresult'] = case self.tqc_state
                         when :pending then 'Pending'
                         when :issues then 'Performed, issues present'
                         when :passed then 'Performed, no issues present'
                         end

    criteria_names = []
    criteria_values = []
    results = self.tqc_spec_with_results
    unless(results.nil?)
      results.each do |criterion|
        criteria_names << criterion['label']
        criteria_values << (criterion['answer'] == true ? 'Pass' : 'Fail')
      end

      result['QCCriteriaNames'] = criteria_names.join("\n")
      result['QCValues'] = criteria_values.join("\n")
    end

    return result
  end
end
