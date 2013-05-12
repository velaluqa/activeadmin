require 'domino_document_mixin'

class ImageSeries < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :name, :visit_id, :patient_id, :imaging_date, :domino_unid
  attr_accessible :visit, :patient

  belongs_to :visit
  belongs_to :patient
  has_many :images, :dependent => :destroy
  has_one :image_series_data
  
  validates_uniqueness_of :name, :scope => :visit_id
  validates_presence_of :name, :patient_id, :imaging_date

  scope :not_assigned, where(:visit_id => nil)

  before_save :ensure_visit_is_for_patient

  after_create do
    ImageSeriesData.create(:image_series_id => self.id)
  end

  before_destroy do
    ImageSeriesData.destroy_all(:image_series_id => self.id)
  end

  def study
    if self.patient.nil?
      nil
    else
      self.patient.study
    end
  end

  def image_series_data
    ImageSeriesData.where(:image_series_id => read_attribute(:id)).first
  end

  def ensure_visit_is_for_patient
    if(self.visit && self.visit.patient != self.patient)
      self.errors[:visit] << 'The visits patient is different from this image series\' patient'
      false
    else
      true
    end
  end

  def previous_image_storage_path
    if(self.previous_changes.include?(:patient_id) || self.previous_changes.include?(:visit_id))
      previous_patient = (self.previous_changes[:patient_id].nil? ? self.patient : Patient.find(self.previous_changes[:patient_id][0]))
      previous_visit = if self.previous_changes[:visit_id].nil?
                         self.visit
                       elsif self.previous_changes[:visit_id][0].nil?
                         nil
                       else
                         Visit.find(self.previous_changes[:visit_id][0])
                       end

      
      if(previous_visit.nil?)      
        previous_patient.image_storage_path + '/__unassigned/' + self.id.to_s
      else
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

  def wado_query
    {:name => self.name, :images => self.images.order('id ASC')}
  end

  def domino_document_form
    'SOFDinventory'
  end
  def domino_document_query
    {
      'docCode' => 10030,
      'CenterNo' => patient.center.code,
      'imaPatNo' => patient.subject_id,
      'imaSeriesNo' => id,
    }
  end
  def domino_document_fields
    ['id', 'imaging_date']
  end
  def domino_document_properties
    {
      'Center' => patient.center.name,
      'CenterNo' => patient.center.code,
      'UIDCenter' => patient.center.domino_unid,
      'PatNo' => patient.domino_patient_no,
      'imaPatNo' => patient.subject_id,
      'imaSeriesNo' => id,
      'imaDateMan' => imaging_date.strftime('%Y%m%d'),
      'imaDateManual' => {'data' => imaging_date.strftime('%d-%m-%Y'), 'type' => 'datetime'}, # this is utterly ridiculous: sending the date in the corrent format (%Y-%m-%d) leads switched month/day for days where this can work (1-12). sending a completely broken format leads to correct parses... *doublefacepalm*
    }

    # from DICOM
    # * imaDate/imaDate2
    # *DICOMn
    # * ImageModality?
    # from study config
    # * DICOMtextn
    # from image_series_data
    # * orientation
    # * region
    # * contrast
    # * comment
  end
end
