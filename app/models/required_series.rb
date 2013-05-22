# note: this is not a proper activerecord model
# it is a simple container class implementing the bare bones needed by the view components of activeadmin

class RequiredSeries
  extend ActiveModel::Naming

  attr_reader :visit, :name
  attr_reader :image_series_id, :assigned_image_series
  attr_reader :tqc_results, :tqc_date, :tqc_version, :tqc_user_id, :tqc_state
  attr_reader :tqc_user

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
    end
  end

  def to_key
    nil
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
end
