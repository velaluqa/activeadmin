module Legacy
  class VisitData
    include Mongoid::Document

    include Mongoid::History::Trackable

    store_in collection: 'visit_data'

    field :visit_id, type: Integer
    field :assigned_image_series_index, type: Hash, default: {}
    field :required_series, type: Hash, default: {}

    field :mqc_results, type: Hash, default: {}
    field :mqc_comment, type: String
    field :mqc_version, type: String

    index visit_id: 1

    track_history track_create: true, track_update: true, track_destroy: true

    def visit
      Visit.find(read_attribute(:visit_id))
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def visit=(visit)
      write_attribute(:visit_id, visit.id)
    end
  end
end
