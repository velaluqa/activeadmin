class Visit < ActiveRecord::Base
  has_paper_trail

  attr_accessible :patient_id, :visit_number, :visit_type
  attr_accessible :patient
  
  belongs_to :patient
  has_many :image_series

  validates_uniqueness_of :visit_number, :scope => :patient_id
  validates_presence_of :visit_number, :visit_type, :patient_id

  before_destroy do
    self.image_series.each do |is|
      is.visit = nil
      is.save
    end
  end

  def name
    if(patient.nil?)
      "Visit No. #{visit_number}"
    else
      "#{patient.name}, Visit No. #{visit_number}"
    end
  end
  def visit_date
    self.image_series.map {|is| is.imaging_date}.reject {|date| date.nil? }.min
  end

  def previous_image_storage_path
    if(self.previous_changes.include?(:patient_id))
      previous_patient = Patient.find(self.previous_changes[:patient_id][0])
      
      previous_patient.image_storage_path + '/' + self.id.to_s
    else
      image_storage_path
    end
  end
  def image_storage_path
    self.patient.image_storage_path + '/' + self.id.to_s
  end

  def wado_query
    {:name => "Visit No. #{visit_number}", :image_series => 
      self.image_series.map {|i_s| i_s.wado_query}
    }
  end

end
