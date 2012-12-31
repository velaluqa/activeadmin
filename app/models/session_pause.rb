class SessionPause < ActiveRecord::Base
  attr_accessible :end, :reason, :session, :start, :last_view, :last_view_id

  belongs_to :session
  belongs_to :last_view, :class_name => 'View'
end
