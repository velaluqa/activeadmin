class MongoidHistoryTracker
  include Mongoid::History::Tracker

  field :modifier_id, type: Integer

  def modifier
    begin
      User.find(read_attribute(:modifier_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
  def modifier=(modifier)
    write_attribute(:modifier_id, (modifier.nil? ? nil : modifier.id))
  end
end
