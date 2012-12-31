class View < ActiveRecord::Base
  belongs_to :session
  belongs_to :patient
  attr_accessible :images, :position, :view_type
  attr_accessible :session_id, :patient_id

  validates_uniqueness_of :position, :scope => :session_id

  # so we always get results sorted by position, not by row id
  default_scope order('position ASC')
end
