class CaseData
  include Mongoid::Document

  include Mongoid::History::Trackable

  field :case_id, type: Integer
  field :data, type: Hash
  field :adjudication_data, type: Hash

  track_history :track_create => true, :track_update => true, :track_destroy => true

  def case
    begin
      return Case.find(read_attribute(:case_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def case=(c)
    write_attribute(:case_id, c.id)
  end
end
