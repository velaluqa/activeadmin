class SessionPause < ActiveRecord::Base
  attr_accessible :end, :reason, :session, :start

  belongs_to :session
end
