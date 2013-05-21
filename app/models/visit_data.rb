class VisitData
  include Mongoid::Document

  field :visit_id, type: Integer
  field :assigned_image_series_index, type: Hash, default: {}
  field :required_series, type: Hash, default: {}

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
end
