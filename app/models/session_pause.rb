class SessionPause < ActiveRecord::Base
  attr_accessible :end, :reason, :session, :start, :sequence_row

  belongs_to :session
end
