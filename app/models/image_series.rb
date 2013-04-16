class ImageSeries < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name, :visit_id, :patient_id
  attr_accessible :visit, :patient

  belongs_to :visit
  belongs_to :patient
  has_many :images, :dependent => :destroy
  
  validates_uniqueness_of :name, :scopy => :visit_id
  validates_presence_of :name, :patient_id

  scope :not_assigned, where(:visit_id => nil)

  def previous_image_storage_path
    if(self.previous_changes.include?(:patient_id) || self.previous_changes.include?(:visit_id))
      if(self.previous_changes[:visit_id][0].nil?)
        previous_patient = (self.previous_changes[:patient_id].nil? ? self.patient : Patient.find(self.previous_changes[:patient_id][0]))
      
        previous_patient.image_storage_path + '/__unassigned' + self.id.to_s
      else
        previous_visit = (self.previous_changes[:visit_id].nil? ? self.visit : Visit.find(self.previous_changes[:visit_id][0]))

        previous_visit.image_storage_path + '/' + self.id.to_s
      end
    else
      image_storage_path
    end
  end
  def image_storage_path
    if(self.visit.nil?)
      self.patient.image_storage_path + '/__unassigned/' + self.id.to_s
    else
      self.visit.image_storage_path + '/' + self.id.to_s
    end
  end
end
