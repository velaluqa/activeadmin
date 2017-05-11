module Legacy
  class MongoidHistoryTracker
    include Mongoid::History::Tracker
    include Mongoid::Document

    store_in collection: 'mongoid_history_trackers'

    field :modifier_id, type: Integer

    def root_version
      query = {
        'association_chain' => association_chain.first,
        'version' => 1
      }
      ::Legacy::MongoidHistoryTracker.where(query).first
    end

    def modifier
      User.find(read_attribute(:modifier_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end

    def modifier=(modifier)
      write_attribute(:modifier_id, (modifier.nil? ? nil : modifier.id))
    end

    def resource
      return nil if association_chain.blank? || association_chain[0]['name'].blank? || association_chain[0]['id'].blank?

      case association_chain[0]['name']
      when 'FormAnswer'
        FormAnswer.where(id: association_chain[0]['id']).first
      when 'CaseData'
        CaseData.where(id: association_chain[0]['id']).first
      when 'PatientData'
        PatientData.where(id: association_chain[0]['id']).first
      when 'ImageSeriesData'
        ImageSeriesData.where(id: association_chain[0]['id']).first
      when 'VisitData'
        VisitData.where(id: association_chain[0]['id']).first
      end
    end
  end
end
