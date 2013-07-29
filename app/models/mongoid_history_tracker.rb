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

  def resource
    return nil if (self.association_chain.blank? or self.association_chain[0]['name'].blank? or self.association_chain[0]['id'].blank?)

    case self.association_chain[0]['name']
    when 'FormAnswer'
      FormAnswer.where(:id => self.association_chain[0]['id']).first
    when 'CaseData'
      CaseData.where(:id => self.association_chain[0]['id']).first
    when 'PatientData'
      PatientData.where(:id => self.association_chain[0]['id']).first
    else
      nil
    end
  end    
end
