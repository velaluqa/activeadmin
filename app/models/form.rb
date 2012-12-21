class Form < ActiveRecord::Base
  has_paper_trail

  attr_accessible :description
  attr_readonly :name, :version

  validates :name, :presence => true
  validates :name, :format => { :with => /^[a-zA-Z0-9_]+$/, :message => 'Only letters A-Z, numbers and \'_\' allowed' }

  belongs_to :session
  has_many :form_answers
end
