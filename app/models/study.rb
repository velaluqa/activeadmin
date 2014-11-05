class Study < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name

  has_many :sessions

  has_many :roles, :as => :subject

  before_destroy do
    unless sessions.empty?
      errors.add :base, 'You cannot delete a study that still has sessions associated with it.'
      return false
    end
  end

  def self.classify_audit_trail_event(c)
    if(c.keys == ['name'])
      :name_change
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
           when :name_change then ['Name Change', :ok]
           end
  end
end
