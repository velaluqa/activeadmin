require 'domino_integration_client'
require 'domino_document_mixin'

class Center < ActiveRecord::Base
  include DominoDocument

  has_paper_trail

  attr_accessible :name, :study, :code, :domino_unid
  attr_accessible :study_id

  belongs_to :study
  has_many :patients

  validates_uniqueness_of :name, :scope => :study_id
  validates_uniqueness_of :code, :scope => :study_id
  validates_presence_of :name, :code, :study_id

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

  def wado_query
    self.patients.map {|patient| patient.wado_query}
  end

  def lotus_notes_url
    self.study.notes_links_base_uri + self.domino_unid unless (self.domino_unid.nil? or self.study.nil? or self.study.notes_links_base_uri.nil?)
  end
  def domino_document_form
    'Center'
  end
  def domino_document_query
    {'docCode' => 10005, 'CenterNo' => self.code}
  end
  def domino_document_fields
    ['code', 'name']
  end
  def domino_document_properties
    {
      'CenterNo' => self.code,
      'CenterShortName' => self.name,
    }
  end
end
