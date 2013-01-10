class SessionPause < ActiveRecord::Base
  attr_accessible :end, :reason, :session, :start, :last_case, :last_case_id

  belongs_to :session
  belongs_to :last_case, :class_name => 'Case'
end
