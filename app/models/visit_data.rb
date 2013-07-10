class VisitData
  include Mongoid::Document

  field :visit_id, type: Integer
  field :assigned_image_series_index, type: Hash, default: {}
  field :required_series, type: Hash, default: {}

  field :mqc_results, type: Hash, default: {}
  field :mqc_comment, type: String
  field :mqc_version, type: String

  index visit_id: 1

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
end
