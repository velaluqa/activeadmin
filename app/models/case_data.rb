class CaseData
  include Mongoid::Document

  field :case_id, type: Integer
  field :data, type: Hash

  index case_id: 1

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
