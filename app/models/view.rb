class View < ActiveRecord::Base
  belongs_to :session
  belongs_to :patient
  belongs_to :form
  attr_accessible :images, :position
  attr_accessible :session_id, :patient_id, :form_id

  validates_uniqueness_of :position, :scope => :session_id

  # so we always get results sorted by position, not by row id
  default_scope order('position ASC')
end
