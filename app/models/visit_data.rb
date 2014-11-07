class VisitData
  include Mongoid::Document

  include Mongoid::History::Trackable

  field :visit_id, type: Integer
  field :assigned_image_series_index, type: Hash, default: {}
  field :required_series, type: Hash, default: {}

  field :mqc_results, type: Hash, default: {}
  field :mqc_comment, type: String
  field :mqc_version, type: String

  index visit_id: 1

  track_history :track_create => true, :track_update => true, :track_destroy => true

  def visit
    begin
      return Visit.find(read_attribute(:visit_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def visit=(visit)
    write_attribute(:visit_id, visit.id)
  end

  def reconstruct_assignment_index
    new_index = {}
    
    self.required_series.each do |rs_name, data|
      next if data['image_series_id'].blank?

      new_index[data['image_series_id']] ||= []
      new_index[data['image_series_id']] << rs_name
    end

    self.assigned_image_series_index = new_index
  end

  def self.classify_mongoid_tracker_event(c)
    diffs = {}
    if c.include?('required_series')
      c['required_series'][:to].each do |rs, to|
        from = c['required_series'][:from][rs] || {}
        diff = to.diff(from)

        diffs[rs] = diff
      end
    end
    pp diffs
    if(c.keys == ['required_series'])
      if(diffs.all? {|rs, diff| (diff.keys - ['domino_unid']).empty?})
        :rs_domino_unid_change
      elsif(diffs.all? {|rs, diff| (diff.keys - ['domino_unid', 'tqc_state', 'tqc_results', 'tqc_date', 'tqc_version', 'tqc_user_id', 'tqc_comment']).empty?})
        :rs_tqc_performed
      end
    elsif((c.keys - ['required_series', 'assigned_image_series_index']).empty?)
      if(diffs.all? {|rs, diff|
           (diff.keys - ['domino_unid', 'image_series_id', 'tqc_state', 'tqc_results', 'tqc_date', 'tqc_version', 'tqc_user_id', 'tqc_comment']).empty? and
             ((diff.keys & ['tqc_results', 'tqc_date', 'tqc_version', 'tqc_user_id', 'tqc_comment']).empty? or
              (
                (diff['tqc_state'].nil? or diff['tqc_state'] == 0) and
                c['required_series'][:to][rs]['tqc_results'].nil? and
                c['required_series'][:to][rs]['tqc_date'].nil? and
                c['required_series'][:to][rs]['tqc_version'].nil? and
                c['required_series'][:to][rs]['tqc_user_id'].nil? and
                c['required_series'][:to][rs]['tqc_comment'].nil?
              )
             )
        })
        :rs_assignment_change
      end
    elsif((c.keys - ['mqc_version', 'mqc_results', 'mqc_comment']).empty?)
      :mqc_performed
    end
  end
  def self.mongoid_tracker_event_title_and_severity(event_symbol)
    return case event_symbol
           when :rs_domino_unid_change then ['RS Domino UNID Change', :ok]
           when :rs_assignment_change then ['RS Assignment Change', :warning]
           when :rs_tqc_performed then ['RS TQC performed', :ok]
           when :mqc_performed then ['MQC performed', :ok]
           end
  end
end
