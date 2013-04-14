class Visit < ActiveRecord::Base
  has_paper_trail

  attr_accessible :patient_id, :visit_number, :visit_type
  attr_accessible :patient
  
  belongs_to :patient
  has_many :image_series, :dependent => :destroy

  validates_uniqueness_of :visit_number, :scopy => :patient_id
  validates_presence_of :visit_number, :visit_type, :patient_id

  def name
    if(patient.nil?)
      "Visit No. #{visit_number}"
    else
      "#{patient.name}, Visit No. #{visit_number}"
    end
  end

  def image_storage_path
    self.patient.image_storage_path + '/' + self.id.to_s
  end
end
