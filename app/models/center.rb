class Center < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name, :study
  attr_accessible :study_id

  belongs_to :study
  has_many :patients

  validates_uniqueness_of :name, :scopy => :study_id
  validates_presence_of :name, :study_id

  before_destroy do
    unless patients.empty?
      errors.add :base, 'You cannot delete a center which has patients associated.' 
      return false
    end

    return true
  end

  def previous_image_storage_path
    if(self.previous_changes.include?(:study_id))
      previous_study = Study.find(self.previous_changes[:study_id][0])
      
      previous_study.image_storage_path + '/' + self.id.to_s
    else
      image_storage_path
    end
  end
  def image_storage_path
    self.study.image_storage_path + '/' + self.id.to_s
  end
end
